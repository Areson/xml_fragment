# xml_fragment

## Overview

The xml_fragment manages xml fragments within xml documents.

## Module Description

The xml_fragment module allows you to manage targeted XML fragments within XML files using xpath.

## Requirements

The xml_fragment module is driven from a ruby-based provider, so it _should_ work on most operating systems. To this date it has only been tested on Windows Server 2012 with Puppet Agent 3.8.0, though it will likely work on others. Please let me know your success/failure with various operating system. It does require REXML to be installed.

## Reference

### Types

#### `xml_fragment`

Manages an XML fragment within an XML file.

* `ensure`: *Optional.* Specifies whether the XML tag specified by the `xpath` parameter should be present or absent. Valid options: 'present' and 'absent'. Default: 'present'.

* `path`: The path to the XML file.

* `xpath`: The xpath for the xml tag to manage. The last tag in the xpath expression will be used as the name of the tag if it does not exist. Example: '/hosts/host[@ip="127.0.0.1"]' would cause the xml_fragment to manage the 'host' tag where the attribute 'id' was equal to localhost.

* `purge`: *Optional.* Specifies if unmanaged children of the XML tag should be removed. Valid options: 'true' and 'false'. Default: 'false'.

* `content`: *Optional.* A hash describing the contents and attributes of the XML tag. Valid keys: 'value' and 'attributes'. The 'value' entry should specify the value of the tag, or be excluded if the tag is empty or will contain children. The 'attributes' entry should be a hash describing the attributes on the tag, where each key/pair in the hash is the attribute/value pair on the tag.

The default behavior of the `xml_fragment` resource is to create or update the tag indicated by the `xpath` parameter. If the tag does not exist it will be created. If it exists the value and attributes of the tag will be updated if needed. Note that if the tag indicated does not have a valid parent tag in the XML document, an error will be thrown. In this XML file, an xpath of '/foo/bar/value' would result in an error because 'bar' does not exist, but '/foo/bar' is valid.

```xml
<foo>
</foo>
```

Setting `ensure` to absent will remove any tags that match the `xpath` parameter, and their children. Purge will also cause the children of any tags matching the `xpath` parameter to be removed, but only if they are not managed by an xml_fragment resource.

### Examples

#### Basic Creation

Create a host entry in the "hosts.xml" file for localhost. If the host does not exist, the entry will be created. Note that the "Hosts" tag must already be present.

```puppet
xml_fragment { "Localhost Host":
    path        => "C:/hosts.xml",
    ensure      => 'present',
    xpath       => "/hosts/host[@ip='127.0.0.1']",
    content     => {
        value   => "Localhost",
        attributes => {
            "ip" => "127.0.0.1"
        }
    }
}
```

### Purge

Given the following XML file template:

```xml
<hosts>
    <host ip="0.0.0.0">Example</host>
</hosts>
```

These xml_fragments will cause our own host to be added to the file and the example host to be removed:

```puppet
xml_fragment { "Hosts":
    path        => "C:/hosts.xml",
    ensure      => 'present',
    xpath       => "/hosts",
    purge       => true
}

xml_fragment { "Localhost Host":
    path        => "C:/hosts.xml",
    ensure      => 'present',
    xpath       => "/hosts/host[@ip='127.0.0.1']",
    content     => {
        value   => "Localhost",
        attributes {
            "ip" => "127.0.0.1"
        }
    }
}
```
