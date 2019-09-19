Puppet::Type.newtype(:xml_fragment) do
  desc 'An XML fragment that exists inside an XML file'

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, 'namevar' => true) do
    desc 'A unique identifier for the XML fragment.'

    munge do |value|
      value.downcase
    end
  end

  newparam(:path) do
    desc 'Full path to the xml file that the XML fragment exists in.'

    validate do |value|
      raise ArgumentError, 'You must specify a path.' unless value
      raise ArgumentError, 'Path must be a string.' unless value.is_a?(String)
    end
  end

  newparam(:xpath) do
    desc 'The xpath of the node to manage. The last XML tag in the xpath will be used as the name of the tag.'

    validate do |value|
      raise ArgumentError, 'You must specify an xpath.' unless value
      raise ArgumentError, 'Xpath must be a string.' unless value.is_a?(String)
    end
  end

  newparam(:purge) do
    desc 'Purge all unmanged XML tags that are children of the tags specified by the xpath parameters.'
    defaultto :false

    newvalues(:true, :false)
  end

  newproperty(:content) do
    desc 'A hash that describes the xml fragment.'

    defaultto {}

    validate do |value|
      raise ArgumentError, '`content` must be a hash.' unless value.is_a?(Hash)
      raise ArgumentError, '`content[\'value\']` must be a string if specified' if value.key?('value') && !value['value'].is_a?(String)

      if value.key?('attributes')
        raise ArgumentError, 'attributes must be a hash.' unless value['attributes'].is_a?(Hash)
        has_contents = false
        value['attributes'].each do |key, val|
          has_contents = true

          # Convert to a string
          unless val.is_a?(String)
            value['attributes'][key] = val.to_s
          end
        end

        raise ArgumentError, 'You must specify at least one attribute for a tag if you include the attributes hash.' unless has_contents
      end
    end

    def insync?(is)
      provider.matches(is, should)
    end

    # def change_to_s(is, should)
    #  "'#{resource[:path]}': Tag <#{resource[:tag]}> -> value was #{is}, changed to #{should}"
    # end

    def is_to_s(is) # rubocop:disable Style/PredicateName
      str = ''
      is.each do |i|
        str += i.to_s
      end

      str
    end

    def should_to_s(should)
      should.to_s
    end
  end
end
