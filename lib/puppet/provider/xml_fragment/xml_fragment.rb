require File.expand_path('../../../util/xml_file', __FILE__)

Puppet::Type.type(:xml_fragment).provide(:xml_fragment) do
	def initialize(args={})
		super(args)	
	end

	def self.tag_regex
		/^(.*?)\/([^\b\[\/]+)(\[[^\]]+\])?$/
	end

	def self.xml_fragment_classvars
		unless @xml_fragment_classvars
			@xml_fragment_classvars = {
				:read_only => {},
				:write_only => {},
				:purge => {}
			}
		end

		@xml_fragment_classvars
	end

	def purge_tags		
		# Use the flush method to manage flushing any resources
		purge = self.class.xml_fragment_classvars[:purge][resource[:path]]
				
		if purge["purgeCount"] > 0 && resource.noop? == false			
			# Go over the resources and mark managed items
			managed = []
			purgeParents = []
			file = self.class.xml_fragment_classvars[:write_only][resource[:path]]

			purge['resourcesCollection'].each do |r|
				found = file.find(r[:xpath])
				managed.concat(found)

				if r[:purge] == :true
					purgeParents.push(r)
				end

				# Mark each of the nodes to note that we don't delete them
				found.each do |node|
					node.add_attribute("Puppet::Util::XmlFile.Managed", true)
				end
			end

			# Iterate through the purge parents and remove immediate children that are no managed			
			purgeParents.each do |p|
				matches = self.class.tag_regex.match(p[:xpath])		
				parent_xpath = matches[1]
				tag_name = matches[2]

				removedElements = file.remove_elements("#{parent_xpath}/#{tag_name}/*[not(@Puppet::Util::XmlFile.Managed)]")			

				if removedElements.length > 0
					Puppet.notice("Removing unmanaged elements #{p[:xpath]}")
				end
			end		

			# Remove the attributes that we added
			managed.each do |node|
				node.delete_attribute("Puppet::Util::XmlFile.Managed")
			end

			file.save()		
		end		
	end

	def content		
		file = self.class.xml_fragment_classvars[:read_only][resource[:path]]
		
		initial_matches = file.find(resource[:xpath])		

		final_matches = []

		initial_matches.each do |m|
			final_matches.push(Puppet::Util::XmlFile.node_to_hash(m))			
		end

		final_matches
	end

	def content=(should)		
		file = self.class.xml_fragment_classvars[:write_only][resource[:path]]

		Puppet.debug("Setting tag: #{@tag_name}, at #{@parent_xpath}, attributes #{@tag_xpath}")

		file.set_tag(@parent_xpath, @tag_name, @tag_xpath, should)
		file.save()
	end

	def exists?
		if !self.class.xml_fragment_classvars[:read_only].has_key?(resource[:path])
			Puppet.debug("Loading file -> #{resource[:path]}")					
			self.class.xml_fragment_classvars[:read_only][resource[:path]] = Puppet::Util::XmlFile.new(resource[:path])
			self.class.xml_fragment_classvars[:write_only][resource[:path]] = Puppet::Util::XmlFile.new(resource[:path])

			# Count the XML resources that are using this file						
			resourcesCollection = resource.catalog.resources.find_all do |r|
				(r.is_a?(Puppet::Type.type(:xml_fragment)) && (r[:path] == resource[:path]))				
		    end
		    
		    purgeCollection = resource.catalog.resources.find_all do |r|
		    	(r.is_a?(Puppet::Type.type(:xml_fragment)) && (r[:path] == resource[:path]) && r[:purge] == :true)				
		    end
		    
		    self.class.xml_fragment_classvars[:purge][resource[:path]] = {
		    	"count"	=> resourcesCollection.length,
		    	"purgeCount" => purgeCollection.length,
		    	"remaining" => 0,		    	
		    	"parents" => [],
		    	"managed" => [],
		    	"resourcesCollection" => resourcesCollection
		    }		    
		end				

		# Split out the tag, tag xpath, and parent xpath
		matches = self.class.tag_regex.match(resource[:xpath])
		test = @parent_xpath ? @parent_xpath : "Nothing!"
		Puppet.debug("Before: #{test}")
		@parent_xpath = matches[1]
		Puppet.debug("After: #{@parent_xpath}")
		Puppet.debug("Getting matches for #{resource[:xpath]}")
		Puppet.debug(matches[1])
		Puppet.debug(matches[2])
		@parent_xpath = matches[1]
		@tag_name = matches[2]
		@tag_xpath = matches[3]

		Puppet.debug("After")
		Puppet.debug("Parent? #{@parent_xpath}")

		# Add this tag to the count of processed tags		
		purge = self.class.xml_fragment_classvars[:purge][resource[:path]]
		
		purge["remaining"] += 1;		

		if (purge["remaining"]) == purge["count"]			
			purge_tags
		end
		
		file = self.class.xml_fragment_classvars[:read_only][resource[:path]]

		# Check to see if the fragment exists in the xml file
		file.file_exists && file.exists(@parent_xpath, @tag_name, @tag_xpath)	
	end

	def create
		Puppet.debug "Attempting to create '#{resource[:xpath]}' in file #{resource[:path]}."
		file = self.class.xml_fragment_classvars[:write_only][resource[:path]]			
		file.set_tag(@parent_xpath, @tag_name, @tag_xpath, resource[:content])
		file.save()	
	end

	def destroy
		Puppet.debug "Attempting to destroy '#{resource[:xpath]}"
		file = self.class.xml_fragment_classvars[:write_only][resource[:path]]

		file.remove_tag(resource[:xpath])
		file.save()
	end
	
	def matches(is, should)
		Puppet.debug "Checking that values match -> is:#{is} / should:#{should}"
		is_match = true

		is.each do |i|
			if should.has_key?("value") && i.has_key?("value") && should["value"] != i["value"]
				is_match = false
				break
			elsif should.has_key?("value") && should["value"] != "" && !i.has_key?("value")
				is_match = false
				break
			elsif !should.has_key?("value") && i.has_key?("value") && i["value"] != ""
				is_match = false
				break
			end

			if should.has_key?("attributes") && i.has_key?("attributes")
				should["attributes"].each do |key, value|
					if !i["attributes"].has_key?(key)
						is_match = false
						break
					elsif i["attributes"][key] != should["attributes"][key]
						is_match = false
						break
					end
				end
			end
		end
		Puppet.debug("Was match: #{is_match}")
		is_match
	end

	def get_mismatches(is, should)
		Puppet.debug "Checking for mismatches"
		Puppet.debug is
		Puppet.debug should
		mismatch = ""

		is.each do |i|
			if should.has_key?("value") && i.has_key?("value") && should["value"] != i["value"]
				mismatch += "Value should be '" + should["value"] + "' but is instead '" + i["value"] + "'.\n"
			elsif should.has_key?("value") && !i.has_key?("value")
				mismatch += "Tag should have a value but it does not.\n"
			elsif !should.has_key?("value") && i.has_key?("value")
				mismatch += "Tag should not hve a value but it does.\n"
			end

			if should.has_key?("attributes") && i.has_key?("attributes")
				should["attributes"].each do |key, value|
					if !i["attributes"].has_key?(key)
						mismatch += "Tag should have an attribute named '" + key + "' but it is missing.\n"
					elsif i["attributes"][key] != should["attributes"][key]
						mismatch += "Tag attribute '" + key + "' should have a value of '" + should["attributes"][key] + "' but instead has a value of '" + i.attributes[key] + "'.\n"						
					end
				end
			end
		end

		Puppet.debug mismatch

		mismatch
	end
end