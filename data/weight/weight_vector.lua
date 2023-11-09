function count_stopcodons(s)
    local pat = "[+*#]"
    local n = 0
    local percent = function(s) n = n + 1 end
    s:gsub(pat, percent)
    return n
   end

function get_weight(gene, regionmapping)
    local fac = 1
    -- apply reward for being annotated by RATT
    if gene:get_source() == "RATT" then
      fac = 1.5
      for c in gene:children() do
        if c:get_type() == 'mRNA' then
          local status, rval = pcall(GenomeTools_genome_node.extract_and_translate_sequence, c, "CDS", true, regionmapping)
          if status then
            prot = rval
            -- ... unless a RATT gene is broken or exceeding boundaries,
            -- in which case disregard it
            if count_stopcodons(prot) > 1 then
              fac = 0
            end
          else
            fac = 0
          end
        end
      end
      -- disregard pseudogenes in reference
      if gene:get_attribute("is_pseudo_in_ref") == 'true' then
        fac = 0
      end
    -- apply constant reward for being annotated by Liftoff
    elseif gene:get_source() == "Liftoff" then
      fac = 1.1
    end
    return gene:get_range():length() * fac
  end