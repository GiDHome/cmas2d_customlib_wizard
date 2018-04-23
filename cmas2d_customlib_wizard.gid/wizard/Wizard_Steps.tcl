
namespace eval ::Cmas2d::Wizard {
    # Namespace variables declaration

}

proc Cmas2d::Wizard::Init { } {

}

# Step 1: Geometry definition window
proc Cmas2d::Wizard::Geometry { win } {
    smart_wizard::AutoStep $win Geometry
}

proc Cmas2d::Wizard::CreateGeometry {} {
    # Clear the model
    GidUtils::ResetModel

    # Create the geometry
    set nvertex [smart_wizard::GetProperty Geometry NVertex,value]
    set radius [smart_wizard::GetProperty Geometry Radius,value]
    GiD_Process Geometry Create Object PolygonPNR $nvertex 0.0 0.0 0.0 0.0 0.0 1.0 $radius escape escape   
    GiD_Process 'Zoom Frame

    # Create group and assign the surface 
    GiD_Groups create "figure"
    GiD_EntitiesGroups assign figure surfaces {1}
    GidUtils::UpdateWindow GROUPS
}

# Step 2: Data definition window
proc Cmas2d::Wizard::Data { win } {
    smart_wizard::AutoStep $win Data
}

proc Cmas2d::Wizard::NextData { } {
     
    # Material
    # Clear the previous tree assignation
    gid_groups_conds::delete {container[@n='Properties']/condition[@n='Shells']/group}

    # Create a part with applied to Shell condition, whose group name is "figure", same group we created in the last step.
    set where {container[@n='Properties']/condition[@n='Shells']} 
    set gnode [customlib::AddConditionGroupOnXPath $where "figure"]
   
    # Set the properties
    set props [list material]
    foreach prop $props {
        set propnode [$gnode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v [smart_wizard::GetProperty Data ${prop},value]
        }
    }
    
    # Loads
    # Delete the previous assignations
    gid_groups_conds::delete {condition[@n='Point_Weight']/group}
    
    # Get the number of vertex of the figure 
    set number_of_vertex [smart_wizard::GetProperty Geometry NVertex,value]
    
    # Get the number of loads
    set number_of_loads [smart_wizard::GetProperty Data NumberOfLoads,value]
    
    # Get the max value for the random weights
    set max_load [smart_wizard::GetProperty Data MaxWeight,value]
    
    # Apply the N loads
    set where {condition[@n='Point_Weight']} 
    set nodes_with_load [list ]
    for {set i 0} {$i < $number_of_loads} {incr i} {
        # Create a new group
        set group_name "Load_$i"
        if {[GiD_Groups exists $group_name]} {GiD_Groups delete $group_name}
        GiD_Groups create $group_name
        
        # Assign a random node on it
        set node [expr {int(rand()*$number_of_vertex)}]
        while {$node in $nodes_with_load || $node<1} {set node [expr 1 + {int(rand()*$number_of_vertex)}]}
        lappend nodes_with_load $node
        GiD_EntitiesGroups assign $group_name points $node 
        
        # Assign the group to the tree
        set group_node [customlib::AddConditionGroupOnXPath $where $group_name]
        
        # Set the random weight value
        set value [format "%.2f" [expr rand()*$max_load]]
        [$group_node selectNodes "./value\[@n = 'Weight'\]"] setAttribute v $value
    }

    gid_groups_conds::actualize_conditions_window
}

proc Cmas2d::Wizard::UpdateMaterial { } {
    set material [smart_wizard::GetProperty Data material,value]
    set node [[customlib::GetBaseRoot] selectNodes "container/container\[@n = 'materials'\]/blockdata\[@name = '$material'\]/value\[@n = 'Density'\]"]
    set density [get_domnode_attribute $node v]
    smart_wizard::SetProperty Data Density "Density: $density"
}

# Step 3: Conditions definition window
proc Cmas2d::Wizard::Run { win } {
    smart_wizard::AutoStep $win Run
}

proc Cmas2d::Wizard::Save { } {
    GiD_Process Mescape Files Save 
}

proc Cmas2d::Wizard::Mesh { } {
     if {[lindex [GiD_Info Mesh] 0]>0} {
          #GiD_Process Mescape Meshing reset Yes
          GiD_Process Mescape Meshing CancelMesh PreserveFrozen Yes
     }
     
     GiD_Process Mescape Meshing Generate DefaultSize escape escape
}

proc Cmas2d::Wizard::Calculate { } {
    GiD_Process Mescape Utilities Calculate
}


Cmas2d::Wizard::Init

