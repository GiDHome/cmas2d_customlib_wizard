# CMas2D Customlib Wizard
An example of [GiD Smart Wizard package](https://github.com/GiDHome/gid_smart_wizard).

## Prélude
This documentation focuses in the "wizard" part of the problemtype, but let's give 5 cents about the "problemtype" part of the files.

### The name
The name cmas2d_customlib_wizard comes from:
* **cmas2d**: Is the problem we are solving. The aim of the problemtype is to calculate the center of mass of a 2D figure. (Or system of coplanar figures).
* **customlib**: Just as a reminder that we are using GiD CustomLib technology to create the problemtype. Using this package we can easily create a tree-based GUI by implementing an xml file (called problemtype_name_default.spd).
* **wizard**: ok... :kissing_heart: 

### The concept
This example extends the cmas2d_customlib example. On the previous one, the user interaction was based on the tree. Now, this tree will be hidden, and the user will interact only with a wizard window. The tree will be hidden, but all the information will be stored there, so this wizard will use the same writing functions as the old one.

Our job here is to define the "windows definition file" and the controller, the tcl script where the steps and the actions are implemented.

## Files

### Problemtype files (for CustomLib based problemtypes)
The files that come from the previuos version:
 * **cmas2d_customlib_wizard_default.spd**: Defines the main tree, the data structure of the problemtype. Even we don't want the tree to be seen, it must be there.
 * **cmas2d_customlib_wizard.tcl**: The main script, where the basic GiD events are implemented.
 
### Wizard files
The files needed for the implementation of the wizard:
* **/wizard/Wizard_default.wiz**: The xml file where the step contents are defined.
* **/wizard/Wizard_Steps.tcl**: The wizard controller. All the functions related with the wizard must be implemented here.

## Initialization
In the main script, we have added in the InitGIDProject project:

```tcl
    # Load the package
    package require gid_smart_wizard
    
    # Init the wizard window
    Cmas2d::StartWizard
```
... and the Cmas2d::StartWindow function:


```tcl
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
```
First of all, we check if GiD is using TK (as you may know, GiD can be executed in a "windowless" mode). 
Init the package, load our step controller file, called /wizard/Wizard_Steps.tcl, and set some variables. See the [Initialize](https://github.com/GiDHome/gid_smart_wizard#initialize) section of the manual.


## Step definition and implementation

Let's start talking about what data is needed in this problemtype, and how this data is organized in steps

### Step 1: Geometry definition

We need to create a random surface, so the first step is called 'Geometry'. It contains 2 frames, the right one contains an image, and the left one has the inputs and the button to create the geometry. In the prevoius problemtype, a 4 side random geometry was generated wich was fine for the example. Now, in order to explain how to implement a button that executes a tcl command, wich takes the value of the items of the window, we allow the user to select the number of vertex and the radius of the geometry.

#### Data

```xml
<Step id="Geometry" title="Geometry definition" subtitle="Create a regular geometry with n vertex">
    <Data>
        <Frame n="Image" position="right">
          <Item n="ImageGeom" v="geometry.jpg" type="image"/>
        </Frame>
        <Frame n="Data" position="left" title="Define geometrical data">
          <Item n="NVertex" pn="Number of vertex" v="5" type="integer" xpath=""/>
          <Item n="Radius" pn="Radius" v="10" type="double" xpath=""/>
          <Item n="DrawButton" pn="Create geometry" type="button" v="Cmas2d::Wizard::CreateGeometry" xpath=""/>
        </Frame>
    </Data>
</Step>
```

#### Tcl implementation
As you learned from the [Controller section](https://github.com/GiDHome/gid_smart_wizard#controller), we need to define a proc called your_wizard_namespace::your_wizard_step_id window_name, in this case **Cmas2d::Wizard::Geometry** win. The great feature of the package gid_smart_wizard towards the gid_wizard package is that we don't need to implement the tk part of the window, we can just call the **smart_wizard::AutoStep** function and let the package work. What we'll need to implement, is the function binded to the Draw button **Cmas2d::Wizard::CreateGeometry**, that takes the values from the window using the [Data Api](https://github.com/GiDHome/gid_smart_wizard#data-api). 

In this step, we don't need to implement the "Next" event, because once the user creates the geometry with the dray button, we don't need to store the data.

```tcl
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
```
#### Result window

The xml section and tcl function above generate the following step window:

![image](https://user-images.githubusercontent.com/5918085/39053452-53de199a-44af-11e8-8f82-5083b574cb76.png)

### Step 2: Data definition

In this section, we will define the material of the figure, the number of random concentrations of mass, and their max value. In order to do that, we are defining 3 frames: one for the image, one the material data, and another for the loads.


#### Data

```xml
<Step id="Data" title="Material and load definition" subtitle="Assign a material to the surface and some random forces">
  <Data>
    <Item n="State" v="0"/>
    <Item n="Active" v="0"/>
    <Item n="Visited" v="0"/>
    <Frame n="Data" position="left" title="Define material data">
      <Item n="material" pn="Material" v="" type="combo" values="[Cmas2d::GetMaterialsRawList]" onchange="Cmas2d::Wizard::UpdateMaterial" xpath="cmas2d_customlib_data/container[@n='Properties']/condition[@n='Shells']/group/value[@n='material']"/>
      <Item n="Density" v="Density: 7850" type="label" xpath=""/>
      <Item n="Info" v="Material properties will be applied when \nyou click Next button" type="label" xpath=""/>
    </Frame>
    <Frame n="Image" position="right" row_span="2">
      <Item n="ImageGeom" v="rammaterial.jpg" type="image"/>
    </Frame>
    <Frame position="left" title="Define loads">
      <Item n="NumberOfLoads" pn="Number of random loads" type="combo" v="1" values="0,1,2,3"/>
      <Item n="MaxWeight" pn="Max weight value of the loads" type="double" v="1e6" units="Kg"/>
      <Item n="Info2" v="Loads will be applied when you click Next button" type="label" xpath=""/>
    </Frame>
  </Data>
</Step>
```

#### Tcl implementation

Same as we did in the previous step, we are using the autogenerated configuration, so we call smart_wizard::AutoStep. Now, we don't have a button to implement a function, we want to bind the **Next** button of the wizard to a function, in order to apply the values of the window into the tree. 

The first we do is to delete previos groups assigned to the Shell condition, with the **gid_groups_conds::delete** function. Then we can create the connection between the Shell condition and the "figure" group, that we created in the last step, using the **customlib::AddConditionGroupOnXPath** function, and set the material, using the tdom function **setAttribute** to set the value into the tree, and the API function smart_wizard::GetProperty to get the value from the window.

```tcl

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
    gid_groups_conds::delete {condition[@n='Point_Weight']/group}
    set number_of_vertex [smart_wizard::GetProperty Geometry NVertex,value]
    set number_of_loads [smart_wizard::GetProperty Data NumberOfLoads,value]
    set max_load [smart_wizard::GetProperty Data MaxWeight,value]
    set where {condition[@n='Point_Weight']} 
    set nodes_with_load [list]
    for {set i 0} {$i < $number_of_loads} {incr i} {
        set group_name "Load_$i"
        set node [expr {int(rand()*4)}]
        while {$node in $nodes_with_load && $node<1} {set node [expr 1 + {int(rand()*$number_of_vertex)}]}
        lappend nodes_with_load $node
        if {[GiD_Groups exists $group_name]} {GiD_Groups delete $group_name}
        GiD_Groups create $group_name
        GiD_EntitiesGroups assign $group_name points $node 
        set group_node [customlib::AddConditionGroupOnXPath $where $group_name]
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

}
```
#### Result window

The xml section and tcl function above generate the following step window:

![image](https://user-images.githubusercontent.com/5918085/39067511-30c739ee-44d9-11e8-9bef-33d3b4c4013b.png)


