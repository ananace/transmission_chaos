# Transmission Chaos

A quick little Ruby application to add some chaos to a running Transmission daemon

Not implemented:
- Authentication
- State keeping
- Proper opt parsing and handling

## Installation

Install it yourself as:

    $ gem install transmission_chaos

## Usage

There's a simple binary provided that will start additional torrents if neccessary to achieve the requested activity level

    $ transmission_chaos http://transmission:9091
     INFO  TransmissionChaos::Client : Less than 10% active (46/502 9%), starting some more
     INFO  TransmissionChaos::Client : Adding chaos with:
    - debian-10.0.0-amd64-netinst.iso
    - Sabayon_Linux_19.03_amd64_KDE.iso
    - debian-10.0.0-amd64-DVD-2.iso
    - Big_Buck_Bunny_1080p_surround_frostclick.com_frostwire.com
    - CentOS-7-x86_64-DVD-1810

Suitably used by adding to a crontab at a wanted interval

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ananace/transmission_chaos

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
