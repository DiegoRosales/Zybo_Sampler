## Script that creates a packaged IP

set  revision 0

## First check if there was a previously packed IP to get the revision and the version
if { [file exists ${packaged_ip_root_dir}/component.xml] == 1} {
    ipx::open_core ${packaged_ip_root_dir}/component.xml
    set revision [get_property core_revision [ipx::current_core]]
    ipx::unload_core ${packaged_ip_root_dir}/component.xml
}

## Pack the project
ipx::package_project -root_dir $packaged_ip_root_dir -vendor xilinx.com -library user -taxonomy /UserIP -import_files -set_current false

## Open the IP Core
ipx::open_core ${packaged_ip_root_dir}/component.xml

## Set the display name and version
set_property name         ${packaged_ip_name}      [ipx::current_core]
set_property version      ${packaged_ip_ver}       [ipx::current_core]
set_property display_name ${packaged_ip_disp_name} [ipx::current_core]
set_property description  ${packaged_ip_name}      [ipx::current_core]

## Increment the revision
incr revision
set_property core_revision $revision [ipx::current_core]

## Generate collaterals
ipx::create_xgui_files [ipx::current_core]

## Update and save
ipx::update_checksums  [ipx::current_core]
ipx::save_core         [ipx::current_core]

## Close
ipx::unload_core ${packaged_ip_root_dir}/component.xml