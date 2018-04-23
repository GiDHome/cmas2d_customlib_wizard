#################################################
#      GiD-Tcl procedures invoked by GiD        #
#################################################
proc InitGIDProject { dir } {
    set Cmas2d::dir $dir  
    Cmas2d::ModifyMenus  
    
    package require gid_smart_wizard

    Cmas2d::StartWizard
}

proc EndGIDProject { } {
    smart_wizard::DestroyWindow
}

proc ChangedLanguage { language } {
    Cmas2d::ModifyMenus
}
 
proc AfterWriteCalcFileGIDProject { filename errorflag } {   
    if { ![info exists gid_groups_conds::doc] } {
        WarnWin [= "Error: data not OK"]
        return
    }    
    set err [catch { Cmas2d::WriteCalculationFile $filename } ret]
    if { $err } {       
        WarnWin [= "Error when preparing data for analysis (%s)" $::errorInfo]
        set ret -cancel-
    }
    return $ret
}


proc AfterMeshGeneration { fail } {
}

proc AfterMeshProgress { } {
    GidUtils::CloseWindow MESHPROGRESS
    GiD_Process Mescape Meshing MeshView 
}

proc BeforeInitGIDPostProcess { } {
    smart_wizard::DestroyWindow
}
proc EndGIDPostProcess { } {
    GidUtils::CloseWindow CUSTOMLIB
}

#################################################
#      namespace implementing procedures        #
#################################################
namespace eval Cmas2d { 
    variable dir
}

proc Cmas2d::StartWizard { } {   
    variable dir
    if { [GidUtils::IsTkDisabled] } {  
        return
    }          
    smart_wizard::Init
    uplevel #0 [list source [file join $dir wizard Wizard_Steps.tcl]]
    smart_wizard::SetWizardNamespace "::Cmas2d::Wizard"
    smart_wizard::SetWizardWindowName ".gid.wizard"
    smart_wizard::SetWizardImageDirectory [file join $dir images]
    smart_wizard::LoadWizardDoc [file join $dir wizard Wizard_default.wiz]
    smart_wizard::ImportWizardData

    smart_wizard::CreateWindow
}

proc Cmas2d::ModifyMenus { } {   
    if { [GidUtils::IsTkDisabled] } {  
        return
    }          
    foreach menu_name {Conditions Interval "Interval Data" "Local axes"} {
        GidChangeDataLabel $menu_name ""
    }       
    GidAddUserDataOptions --- 1    
    GidAddUserDataOptions [= "Data tree"] [list GidUtils::ToggleWindow CUSTOMLIB] 2
    set x_path {/*/container[@n="Properties"]/container[@n="materials"]}
    GidAddUserDataOptions [= "Import/export materials"] [list gid_groups_conds::import_export_materials .gid $x_path] 3
    GidAddUserDataOptions [= "Wizard window"] [list smart_wizard::CreateWindow] 4
    GiDMenu::UpdateMenus
}

######################################################################
#  auxiliary procs invoked from the tree (see .spd xml description)
proc Cmas2d::GetMaterialsList { domNode args } {  
    set image material
    set result [list]
    foreach name [Cmas2d::GetMaterialsRawList] {
        lappend result [list 0 $name $name $image 1]
    }
    return [join $result ,]
}
proc Cmas2d::GetMaterialsRawList { } {
    set x_path {//container[@n="materials"]}
    set dom_materials [[customlib::GetBaseRoot] selectNodes $x_path]
    if { $dom_materials == "" } {
        error [= "xpath '%s' not found in the spd file" $x_path]
    }
    set result [list]
    foreach dom_material [$dom_materials childNodes] {
        lappend result [$dom_material @name] 
    }
    return $result
}

proc Cmas2d::EditDatabaseList { domNode dict boundary_conds args } {
    set has_container ""
    set database materials    
    set title [= "User defined"]      
    set list_name [$domNode @n]    
    set x_path {//container[@n="materials"]}
    set dom_materials [$domNode selectNodes $x_path]
    if { $dom_materials == "" } {
        error [= "xpath '%s' not found in the spd file" $x_path]
    }
    set primary_level material
    if { [dict exists $dict $list_name] } {
        set xps $x_path
        append xps [format_xpath {/blockdata[@n=%s and @name=%s]} $primary_level [dict get $dict $list_name]]
    } else { 
        set xps "" 
    }
    set domNodes [gid_groups_conds::edit_tree_parts_window -accepted_n $primary_level -select_only_one 1 $boundary_conds $title $x_path $xps]          
    set dict ""
    if { [llength $domNodes] } {
        set domNode [lindex $domNodes 0]
        if { [$domNode @n] == $primary_level } {      
            dict set dict $list_name [$domNode @name]
        }
    }
    return [list $dict ""]
}

###################################################################################
#      print data in the .dat calculation file (instead of a classic .bas template)
proc Cmas2d::WriteCalculationFile { filename } {
    customlib::InitWriteFile $filename
    set elements_conditions [list "Shells"]
    # This instruction is mandatory for using materials
    customlib::InitMaterials $elements_conditions active
    customlib::WriteString "=================================================================="
    customlib::WriteString "                        General Data File"    
    customlib::WriteString "=================================================================="
    customlib::WriteString "Units:"
    customlib::WriteString "length [gid_groups_conds::give_active_unit L] mass [gid_groups_conds::give_active_unit M]"
    customlib::WriteString "Number of elements and nodes:"
    customlib::WriteString "[GiD_Info Mesh NumElements] [GiD_Info Mesh NumNodes]"    
    customlib::WriteString ""
    customlib::WriteString "................................................................."    
    #################### COORDINATES ############################ 
    set units_mesh [gid_groups_conds::give_mesh_unit]
    customlib::WriteString ""
    customlib::WriteString "Coordinates:"
    customlib::WriteString "  Node        X $units_mesh               Y $units_mesh"
    # Write all nodes of the model, and it's coordinates
    # Check documentation to write nodes from an specific condition
    
    # 2D case
    customlib::WriteCoordinates "%5d %14.5e %14.5e%.0s\n"
    # Example for 3D case
    #customlib::WriteCoordinates "%5d %14.5e %14.5e %14.5e\n"
    #################### CONNECTIVITIES ############################    
    customlib::WriteString ""
    customlib::WriteString "................................................................."
    customlib::WriteString ""
    customlib::WriteString "Connectivities:"
    customlib::WriteString "    Element    Node(1)   Node(2)   Node(3)     Material"
    set element_formats [list {"%10d" "element" "id"} {"%10d" "element" "connectivities"} {"%10d" "material" "MID"}]
    customlib::WriteConnectivities $elements_conditions $element_formats active 
    #################### MATERIALS ############################
    set num_materials [customlib::GetNumberOfMaterials used]
    customlib::WriteString ""
    customlib::WriteString "................................................................."
    customlib::WriteString ""
    customlib::WriteString "Materials:"
    customlib::WriteString $num_materials
    customlib::WriteString "Material      Surface density [gid_groups_conds::give_active_unit M/L^2]"
    customlib::WriteMaterials [list {"%4d" "material" "MID"} {"%13.5e" "material" "Density"}] used active
    #################### CONCENTRATE WEIGHTS ############################
    customlib::WriteString ""
    customlib::WriteString "................................................................."
    customlib::WriteString ""
    set condition_list [list "Point_Weight"]
    set condition_formats [list {"%1d" "node" "id"} {"%13.5e" "property" "Weight"}]
    set number_of_conditions [customlib::GetNumberOfNodes $condition_list]
    customlib::WriteString "Concentrate Weights:"
    customlib::WriteString $number_of_conditions
    customlib::WriteString "Node   Mass [gid_groups_conds::give_active_unit M]"
    customlib::WriteNodes $condition_list $condition_formats "" active
    customlib::EndWriteFile ;#finish writting
}
