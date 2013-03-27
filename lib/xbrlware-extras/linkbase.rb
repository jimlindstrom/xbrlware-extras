module Xbrlware

  module Linkbase
    class Linkbase
      class Link
        def clean_downcased_title
          @title.gsub(/([A-Z]) ([A-Z])/, '\1\2').gsub(/([A-Z]) ([A-Z])/, '\1\2').downcase
        end
      end
    end

    class CalculationLinkbase
      class Calculation
        def write_constructor(file, calc_name)
          file.puts "#{calc_name}_args = {}"
          file.puts "#{calc_name}_args[:title] = \"#{@title}\""
          file.puts "#{calc_name}_args[:role] = \"#{@role}\""
          file.puts "#{calc_name}_args[:arcs] = []"
          @arcs.each_with_index do |arc, index|
            arc_name = calc_name + "_arc#{index}"
            arc.write_constructor(file, arc_name)
            file.puts "#{calc_name}_args[:arcs].push #{arc_name}"
          end
          file.puts "#{calc_name} = Xbrlware::Factory.Calculation(#{calc_name}_args)"
        end

        def is_disclosure?
          return true if @title.downcase =~ /^disclosure/ 
          return true if @title.downcase =~ /^summary of/
          return true if @title.downcase =~ /details$/
          return false
        end

        def top_level_arcs
          uniq_arcs = []
          @arcs.each do |arc|
            if @arcs.none?{ |other_arc| other_arc.contains_arc?(arc) }
              uniq_arcs.push arc
            end
          end

          return uniq_arcs
        end

        def sort!(args)
          @arcs = @arcs.sort do |x,y|
            xscore = 0
            yitems = y.leaf_items(args[:period])
            x.leaf_items(args[:period]).each do |xnode|
              yitems.each do |ynode|
                xscore = (xnode <=> ynode) # NOTE: Assumes caller has defined <=> for all leaf nodes
              end
            end
            puts "\"#{x.pretty_name}\" #{xscore <=> 0} \"#{y.pretty_name}\""
            xscore <=> 0
          end
          @arcs.each{ |arc| arc.sort!(args) }
        end

        def sprint_tree(indent_count=0, simplified=false)
          indent = " " * indent_count
          output = indent + "Calc: #{@title} (#{@role})" + "\n"

          #@arcs.each { |arc| output += arc.sprint_tree(indent_count+1, simplified) }
          top_level_arcs.each { |arc| output += arc.sprint_tree(indent_count+1, simplified) }

          output += indent + "\n\n"
          output
        end

        def print_tree(indent_count=0, simplified=false)
          puts sprint_tree(indent_count, simplified)
        end

        def leaf_items(period)
          #if @arcs.empty?
          if top_level_arcs.empty?
            raise RuntimeError.new("#{self.inspect} (#{@label}) has nil items!") if @items.nil?

            items = @items.select{ |x| !x.is_sub_leaf? }
            items.select!{ |x| x.context.period.to_pretty_s == period.to_pretty_s } if period

            return items
          end
    
          #return @arcs.collect { |child| child.leaf_items(period) }.flatten
          return top_level_arcs.collect { |child| child.leaf_items(period) }.flatten
        end
    
        class CalculationArc
          def write_constructor(file, arc_name)
            file.puts "args = {}"
            file.puts "args[:item_id] = \"#{@item_id}\""
            file.puts "args[:label] = \"#{@label}\""
            file.puts "#{arc_name} = Xbrlware::Factory.CalculationArc(args)"
            file.puts "#{arc_name}.items = []"
            (@items || []).each_with_index do |item, index|
              item_name = arc_name + "_item#{index}"
              item.write_constructor(file, item_name)
              file.puts "#{arc_name}.items.push #{item_name}"
            end
            file.puts "#{arc_name}.children = []"
            (@children || []).each_with_index do |child, index|
              child_name = arc_name + "_child#{index}"
              child.write_constructor(file, child_name)
              file.puts "#{arc_name}.children.push #{child_name}"
            end
          end

          def sort!(args)
            if @children
              @children = @children.sort do |x,y|
                xscore = 0
                yitems = y.leaf_items(args[:period])
                x.leaf_items(args[:period]).each do |xnode|
                  yitems.each do |ynode|
                    xscore = (xnode <=> ynode) # NOTE: Assumes caller has defined <=> for all leaf nodes
                  end
                end
                puts "\"#{x.label}\" #{xscore <=> 0} \"#{y.label}\""
                xscore <=> 0
              end
            end
            (@children || []).each{ |child| child.sort!(args) }
          end

          def contains_arc?(arc)
            return false if @children.empty?

            @children.each do |child|
              return true if (child.label == arc.label) && (child.item_id == arc.item_id)
              return true if child.contains_arc?(arc)
            end

            return false
          end

          def sprint_tree(indent_count=0, simplified=false)
            indent = " " * indent_count
            str = "#{indent} CA:#{@label}"

            if simplified
              (@items.last(1) || []).each do |item|
                str += " I:{#{item.pretty_name}} "
                # FIXME: First off, sub-leaf is terrible, non-standard, confusing terminology. Call it something else.
                # FIXME: Second, why aren't we calling Item::print_tree()?
                if item.is_sub_leaf?
                  str += " [sub-leaf]"
                else
                  str += " [non-sub-leaf]"
                end
                period = item.context.period
                period_str = period.is_duration? ? "#{period.value["start_date"]} to #{period.value["end_date"]}" : "#{period.value}"
                str += " [#{item.def["xbrli:balance"]}]" if item.def && item.def["xbrli:balance"]
                str += " (#{period_str}) = #{item.value}" if item.value
              end
            else
              (@items || []).each do |item|
                str += " I:{#{item.pretty_name}} "
                if item.is_sub_leaf?
                  str += " [sub-leaf]"
                else
                  str += " [non-sub-leaf]"
                end
                period = item.context.period
                period_str = period.is_duration? ? "#{period.value["start_date"]} to #{period.value["end_date"]}" : "#{period.value}"
                str += " [#{item.def["xbrli:balance"]}]" if item.def && item.def["xbrli:balance"]
                str += " (#{period_str}) = #{item.value}" if item.value
              end
            end
            output = indent + str + "\n"

            (@children || []).each { |child| output += child.sprint_tree(indent_count+1, simplified) }
            output
          end

          def print_tree(indent_count=0, simplified=false)
            puts sprint_tree(indent_count, simplified)
          end

          def leaf_items(period)
            if @children.empty?
              raise RuntimeError.new("#{self} (#{@label}) has nil items!") if @items.nil?
              items = @items.select{ |x| !x.is_sub_leaf? }
              raise RuntimeError.new("#{self} (#{@label}) has a Hash for a period") if period and period.class==Hash
              items.select!{ |x| x.context.period.to_pretty_s == period.to_pretty_s } if period
              return items
            end
      
            return @children.collect { |child| child.leaf_items(period) }.flatten
          end
        end
      end
    end

    class PresentationLinkbase
      class Presentation
        def sprint_tree(indent_count=0, simplified=false)
          indent = " " * indent_count
          output = indent + "Pres: #{@title} (#{@role})" + "\n"

          @arcs.each { |arc| output += arc.sprint_tree(indent_count+1, simplified) }

          output += indent + "\n\n"
          output
        end

        def print_tree(indent_count=0, simplified=false)
          puts sprint_tree(indent_count, simplified)
        end

        class PresentationArc
          def sprint_tree(indent_count=0, simplified=false)
            indent = " " * indent_count
            str = "#{indent} #{@label}"

            @items.each do |item|
              period=item.context.period
              period_str = period.is_duration? ? "#{period.value["start_date"]} to #{period.value["end_date"]}" : "#{period.value}"
              str += " [#{item.def["xbrli:balance"]}]" unless item.def.nil?
              str += " (#{period_str}) = #{item.value}" unless item.nil?
            end
            output = indent + str + "\n"

            @children.each { |child| output += child.sprint_tree(indent_count+1, simplified) }
            output
          end

          def print_tree(indent_count=0, simplified=false)
            puts sprint_tree(indent_count, simplified)
          end
        end
      end
    end
  end

end
