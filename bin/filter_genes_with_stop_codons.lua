#!/usr/bin/env gt

--[[
  Author: Sascha Steinbiss <ss34@sanger.ac.uk>
  Copyright (c) 2014-2015 Genome Research Ltd

  Permission to use, copy, modify, and distribute this software for any
  purpose with or without fee is hereby granted, provided that the above
  copyright notice and this permission notice appear in all copies.

  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
]]

package.path = gt.script_dir .. "/?.lua;" .. package.path
require("optparse")
local json = require ("dkjson")

op = OptionParser:new({usage="%prog <options> <GFF annotation> <sequence>",
                       oneliner="Convert any remaining genes with stop codons to pseudogene.",
                       version="0.2"})
op:option{"-m", action='store', dest='mapping',
                help="reference target chromosome mapping"}
op:option{"-b", action='store', dest='mit_bypass',
                help="prevent removal for mitochondrial genes (default: false)"}
options,args = op:parse({mapping=nil, mit_bypass="false"})

function usage()
  op:help()
  os.exit(1)
end

if #args < 2 then
  usage()
end

if options.mapping then
  local mapfile = io.open(options.mapping, "rb")
  if not mapfile then
    error("could not open reference target mapping file")
  end
  local mapcontent = mapfile:read("*all")
  mapfile:close()
  ref_target_mapping = json.decode(mapcontent)
else
  ref_target_mapping = nil
end

region_mapping = gt.region_mapping_new_seqfile_matchdescstart(args[2])

outvis = gt.gff3_visitor_new()

visitor = gt.custom_visitor_new()
visitor.last_seqid = nil
function visitor:visit_feature(fn)
  local has_stop = false
  local protseq = nil
  local bypass = false
  if ref_target_mapping and options.mit_bypass == "true" then
    -- bypass conversion to pseudogene if required for mitochondrial gene
    if ref_target_mapping.MIT and fn:get_seqid() == ref_target_mapping.MIT[2] then
      bypass = true
    end
  end
  for node in fn:children() do
    if node:get_type() == "mRNA" then
      -- catch invalid sequence accesses here to make sure we don't fail hard
      -- this should be sorted out later -- how do we end up with these
      -- coordinates?
      val, protseq = pcall(GenomeTools_genome_node.extract_and_translate_sequence,
                           node, "CDS", true, region_mapping)
      if not val then
        io.stderr:write(protseq .. "\n")
        io.stderr:write("gene accessing invalid sequence region :" ..
                        fn:get_attribute("ID") .. ", skipped\n")
        return
      end
      if protseq:sub(1, -2):match("[*+#]") then
        has_stop = true
        break
      end
    end
  end
  -- make this a pseudogene
  if has_stop and not bypass then
    local npseudogene = nil
    local nptranscript = nil
    local npexon = nil
    for node in fn:children() do
      local rng = node:get_range()
      if node:get_type() == "gene" then
        npseudogene = gt.feature_node_new(node:get_seqid(), "pseudogene",
                                          rng:get_start(), rng:get_end(),
                                          node:get_strand())
        for k,v in node:attribute_pairs() do
          npseudogene:set_attribute(k, v)
        end
        npseudogene:set_attribute("has_internal_stop", "true")
        local rorth = npseudogene:get_attribute("ratt_ortholog")
        if rorth and protseq then
          npseudogene:set_attribute("Target", rorth .. " 1 " ..
                                    string.len(protseq))
        end
      elseif node:get_type() == "mRNA" then
        assert(npseudogene)
        nptranscript = gt.feature_node_new(node:get_seqid(),
                                           "pseudogenic_transcript",
                                           rng:get_start(), rng:get_end(),
                                           node:get_strand())
        npseudogene:add_child(nptranscript)
        for k,v in node:attribute_pairs() do
          nptranscript:set_attribute(k, v)
        end
      elseif node:get_type() == "CDS" then
        assert(nptranscript)
        npexon = gt.feature_node_new(node:get_seqid(),
                                     "pseudogenic_exon",
                                     rng:get_start(), rng:get_end(),
                                     node:get_strand())
        nptranscript:add_child(npexon)
        for k,v in node:attribute_pairs() do
          -- do not clone IDs
          if k ~= 'ID' then
            npexon:set_attribute(k, v)
          end
        end
      end
    end
    if npseudogene then
      npseudogene:accept(outvis)
    end
  else
    fn:accept(outvis)
  end
  return 0
end

-- make simple visitor stream, just applies given visitor to every node
visitor_stream = gt.custom_stream_new_unsorted()
function visitor_stream:next_tree()
  local node = self.instream:next_tree()
  if node then
    node:accept(self.vis)
  end
  return node
end

visitor_stream.instream = gt.gff3_in_stream_new_sorted(args[1])
visitor_stream.vis = visitor
local gn = visitor_stream:next_tree()
while (gn) do
  gn = visitor_stream:next_tree()
end

