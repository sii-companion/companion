#!/usr/bin/env gt
function usage()
  io.stderr:write(string.format("Usage: %s <Transfer.*.final.embl> [<Transfer.*.final.embl> ...]>\n" , arg[0]))
  os.exit(1)
end

if #arg < 1 then
  usage()
end

package.path = gt.script_dir .. "/?.lua;" .. package.path
require("lib")

genes = {}
geneno = 1
cur_gene = nil
for i = 1,#arg do
  local seqid = nil
  for l in io.lines(arg[i]) do
    if l:sub(1,2) == "ID" then
      seqid = l:match("[^.]+.(.*).final")
    elseif seqid and (l:match("locus_tag=") or l:match("systematic_id=")) then
      local ltag = l:match('locus_tag="([^"]+)"')
      if not ltag then
        ltag = l:match('systematic_id="([^"]+)"')
      end
      if ltag and cur_gene and not cur_gene:get_attribute("ratt_ortholog") then
        cur_gene:set_attribute("ratt_ortholog", ltag)
      end
    elseif seqid and cur_gene and l:match("     /pseudo") then
      cur_gene:set_attribute("is_pseudo_in_ref", "true")
    elseif seqid and l:match("%srRNA%s")  then
      cur_gene = nil
      if l:match("complement") then
        strand = "-"
      else
        strand = "+"
      end
      local ncrnas = {}
      local totalrange = nil
      local exnr = 1
      for s,e in l:gmatch("(%d+)%.%.(%d+)") do
        if (tonumber(s) <= tonumber(e)) then
          local thisrng = gt.range_new(tonumber(s), tonumber(e))
          if not totalrange then
            totalrange = thisrng
          else
            totalrange = totalrange:join(thisrng)
          end
          node = gt.feature_node_new(seqid, "rRNA", tonumber(s), tonumber(e),
                                    strand)
          node:set_attribute("ID",  "RATTgene" .. geneno .. ".rRNA"..exnr)
          node:set_source("RATT")
          table.insert(ncrnas, node)
          exnr = exnr + 1
        else
          io.stderr:write("error: malformed input range " .. s .. "-"
                          .. e .. ", skipping\n")
          --reset totalrange to disable gene output
          totalrange = nil
          break
        end
      end
      if totalrange then
        gene = gt.feature_node_new(seqid, "gene",
                                   totalrange:get_start(),
                                   totalrange:get_end(),
                                   strand)
        gene:set_attribute("ID", "RATTgene"..geneno)
        gene:set_source("RATT")
        for _,n in pairs(ncrnas) do
          gene:add_child(n)
        end
        table.insert(genes, gene)
        cur_gene = gene
        geneno = geneno + 1
      end
    end
  end
end

vis_stream = gt.custom_stream_new_unsorted()
vis_stream.queue = genes
function vis_stream:next_tree()
  if table.getn(self.queue) > 0 then
    return table.remove(self.queue, 1)
  else
    return nil
  end
end

out_stream = gt.gff3_out_stream_new(vis_stream)
local gn = out_stream:next_tree()
while (gn) do
  gn = out_stream:next_tree()
end