## Build the workspace

setws ${workspace_project_path}
repo -set ${fw_source_path}/repo
app create -name ${app_project_name} -hw ${workspace_project_path}/${platform_project_name}.xsa -proc {ps7_cortexa9_0} -os freertos10_xilinx_sampler -lang C -template {Empty Application}
driver -peripheral ps7_sd_0 -name sdps -ver 3.8

## Configure FreeRTOS BSP
bsp config num_thread_local_storage_pointers 4
bsp config max_task_name_len                 50        ;# Task names can be 50 haracters long
bsp config total_heap_size                   268435456 ;# 256Mib

source $filelists_path/fw_incdirs.f
source $filelists_path/fw_softlinks.f

## Create the softlinks
foreach softlink $fw_softlinks {
    lassign $softlink softlink_target softlink_source
    file link -symbolic ${workspace_project_path}/${app_project_name}/src/${softlink_target} ${softlink_source}
}

## Add the include directories
foreach incdir $fw_incdirs {
    set base_dir {${workspace_loc:/${ProjName}/src}}
    set full_incdir ${base_dir}/${incdir}
    app config -name ${app_project_name} -add include-path $full_incdir
}

platform generate