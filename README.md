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

## Data definition

Let's start talking about what data is needed in this problemtype, and how this data is organized in steps

### Step 1: Geometry definition

We need to create a random surface, so the first step is called 'Geometry'. It contains 2 frames, the right one contains an image, and the left one has the inputs and the button to create the geometry.

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
