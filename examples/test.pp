class xml_fragment::test {
    file { "c:/test.xml":
        ensure => 'file',
        content => "<server><hosts><host ip='0.0.0.0'>Example</host></hosts><remove>Remove me!</remove></server>"
    }

    xml_fragment { "Hosts":
        path        => "c:/test.xml",
        xpath       => "/server/hosts",
        purge       => true
    }

    xml_fragment { "Host custom":
        path        => "c:/test.xml",
        xpath       => "/server/hosts/host[@ip='sam']",
        content     => {
            value => 'Sam',
            attributes => {
                "ip" => 'sam',
                "at" => 'val'
            }
        }
    }

    xml_fragment { "Remove":
        path        => "c:/test.xml",
        xpath       => "/server/remove",
        ensure      => absent
    }
}