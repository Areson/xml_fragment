require "rexml/document"

# Override the REXML pretty printer to prevent text wrapping
class MyPrecious < REXML::Formatters::Pretty
    def write_text( node, output )
        s = node.to_s()
        s.gsub!(/\s/,' ')
        s.squeeze!(" ")

        #The Pretty formatter code mistakenly used 80 instead of the @width variable
        #s = wrap(s, 80-@level)
        s = wrap(s, @width-@level)

        s = indent_text(s, @level, " ", true)
        output << (' '*@level + s)
    end
end

module Puppet
module Util
	class XmlFile		
		def initialize(path)
			@does_exist = false
			@document = REXML::Document.new
			@path = path

			if File.file?(@path)
				@does_exist = true

				File.open(@path, 'r') do |file_contents|
					@document = REXML::Document.new(file_contents)
				end
			end		
		end

		def file_exists
			@does_exist
		end

		# Find all nodes for a give URI
		def find(xpath)
			REXML::XPath.match(@document, xpath)
		end

		def matches(xpath, value)
			does_match = true			

			candidates = find(xpath)

			if candidates.length > 0
				candidates.each do |node|
					if !node_matches(node, value)
						does_match = false
						break
					end
				end
			else
				does_match = false
			end
			
			does_match
		end

		def node_matches(node, value)
			# Is this a text only node?
			if !node.has_elements?
				if value && value.has_key?("value") && value["value"] != "" && node.text != value["value"]
					return false
				end
			end

			if value.has_key?("attributes") && node.has_attributes?()
				value["attributes"].each do |key, value|
					test_attribute = node.attributes.get_attribute(key)

					if !test_attribute || test_attribute.value() != value
						return false											
					end
				end							
			elsif value.has_key?("attributes") != node.has_attributes?()
				return false
			end

			return true
		end

		def remove_elements(xpath)
			Puppet.debug "Removing elements for #{xpath}"
			@document.root.elements.delete_all(xpath)
		end

		def exists(xpath, tag, tag_xpath)
			parent_found = false
			does_exist = true

			REXML::XPath.each(@document, xpath) do |parent|
				parent_found = true
				if REXML::XPath.match(parent, "./#{tag}#{tag_xpath}").length == 0
					does_exist = false
					break
				end
			end

			does_exist && parent_found
		end

		def set_tag(xpath, tag, tag_xpath, value)
			matches = nil
			parent_found = false
			
			Puppet.notice("Xpath: #{xpath}")

			REXML::XPath.each(@document, xpath) do |node|				
				if node.is_a?(REXML::Element)
					was_found = false
					parent_found = true
					
					REXML::XPath.each(node, "./#{tag}#{tag_xpath}") do |child|
						was_found = true
												
						if value && value.has_key?("value")
							child.text = value["value"]
						end
						
						if value && value.has_key?("attributes")
							value["attributes"].each do |key, value|
								child.attributes[key] = value
							end
						end					
					end			

					if !was_found												
						new_element = REXML::Element.new(tag)
						
						if value.has_key?("value")
							new_element.text = value["value"]
						end
						
						if value.has_key?("attributes")
							new_element.add_attributes(value["attributes"])
						end						

						node.add_element(new_element)
					end
				end
			end

			raise ArgumentError, "Unable to set <#{tag}>. No parents found for the xpath #{xpath}" if !parent_found
		end

		def remove_tag(xpath)			
			@document.elements.delete_all(xpath)							
		end

		def save
			File.open(@path, 'w') do |file_contents|
				formatter = MyPrecious.new
				formatter.width = 10000
				formatter.compact = true
				formatter.write(@document, file_contents)
				#@document.write(file_contents)
			end
		end

		# Static helper methods
		def self.node_to_hash(node)
			new_hash = Hash.new

			if !node.has_elements? && node.text && node.text != ""
				new_hash["value"] = node.text
			end

			if node.has_attributes?
				new_hash["attributes"] = Hash.new
				
				node.attributes.each do |a|
					new_hash["attributes"][a[0]] = a[1]
				end
			end	

			Puppet.debug "Converted hash: #{new_hash}"			

			new_hash
		end

		private
		def build_xpath(xpath, tag, uri)
			xpath + (xpath.end_with?("/") ? "" : "/") + build_tag_uri(tag, uri)
		end

		def build_tag_uri(tag, uri)
			(tag ? tag : "*") + (uri ? ("[@uri=\"" + uri + "\"]") : "")
		end
	end
end
end