Sketchup To Ogre Exporter  Version 1.1.0
Written by Kojack


This is a ruby based script for Sketchup which can export 3d scenes to the Ogre rendering engine.
It is released under the LGPL.

To contact me, I'm on the Ogre forums (http://www.ogre3d.org/phpBB2).


Installation
------------

Along with this readme.txt, you should have received files called ogre_export.rb, ogre_export.htm, ogre_config.rb and backface.rb. All 4 of those files should be placed in the Sketchup plugin directory. For example, this may be c:\Program Files\Google\Google SketchUp\Plugins. The ogre_export.htm is not a help file! It's used to generate the configuration options dialog.

It is no longer nessessary to edit ogre_config.rb by hand. There is now a user interface when exporting which lets you change configuration options.


Usage
-----

There are 2 components within this package, A back face tool and an exporter. Both place menu items in the Tools menu.

Backface
The back face tool allows easier handling of back faces. Sketchup allows backfaces as a valid surface, whereas 3d engines like Ogre default to hiding back faces to speed up rendering.

Select the "Highlight Backfaces" menu item to colour the back of every face to bright pink. This lets you easily spot which back faces are visible. Don't worry, the materials which were on the backfaces are preserved, and can be restored (keep reading...). Any bright pink surface you can see in your model will be completely invisible in Ogre.

Select the "Unhighlight Backfaces" menu item to restore the original materials to the back faces. Note: if you use "Highlight Backfaces" several times, any face which hasn't been unhighlighted will lose it's original texture (I'll fix that at some point).

Select the "Flip Backface" menu item to restore the original material to the selected face, and also swap the front and back faces (without changing the direction of the material. Sketchup has a build in tool to reverse the direction of a face, but it will swap which sides the materials are on too.



Exporter
The exporter has a menu item in the Tools menu, called "Export To Ogre".

When you select the export menu item, you will be presented with a dialog of export options. These options are saved when you press the "Export" button (to ogre_config.rb), and abandoned when you press the "Cancel" button.
The options are as follows:

Export Style - What kind of export to perform (single mesh, dotScene or oFusion OSM). Only mesh is supported in this version.
Export Name - This is the start of the filename used for both meshes and materials. If you enter "test", then your output files will be called "test.mesh.xml" and "test.materials". Do not manually add the extensions, they are added automatically.
Export Materials - If the checkbox is ticked, then a material file is exported to the directory listed in the text box.
Export Meshes - If the checkbox is ticked, then a mesh is exported to the directory listed in the text box as an xml file.
Export Textures - If the checkbox is ticked, then all required textures are copied into the directory listed in the text box.
Run XML Converter - If the checkbox is ticked, the mesh (in xml form) is passed to the program listed in the text box. The program should be the standard OgreXMLConverter.exe file. You need to specify the path and executable name (eg. c:\ogre\bin\OgreXMLConverter.exe).

Export Default Materials - If the checkbox is ticked, 2 extra materials are exported. These match the default front and back face colours in Sketchup. They are called SketchupDefault and SketchupDefault_Back.
Front Faces - The exported mesh will include front faces.
Back Faces - The exported mesh will include back faces. (This will double the polygon count, avoid it if possible)
Root Faces - Export faces which are in the root of the scene (not part of a component).
Merge Child Components - Not currently used (intended for scene export).
Selection Only - If the checkbox is ticked, only the currently selected objects will be exported. Otherwise, everything is exported.

Scale - Click on the Inches, Centimeters or Meters buttons to set the scale of your Ogre units, or enter a scale manually. Sketchup uses a scale of 1 unit = 1 inch.


Notes:
- Materials with spaces in their name will have them replaced with underscores during export (but only in the exported files, the material in Sketchup isn't renamed). Other symbols may confuse Ogre's material system, so try to keep material names to basic alphanumeric characters.
- Texture file names will have spaces replaced with underscores.
- Edges aren't exported. If your model relies on edges for showing detail, you won't see them in Ogre. This may be added in a later version (will require changes to Ogre).
- This tool was tested only in the free version of Google Sketchup. Compatibility with Sketchup Pro is unknown.
- Try to avoid backfaces if possible. Lots of sketchup models have backfaces facing outwards, or use both front and back faces to make thin walls. 3D engines don't like this, so if both the front and back face checkboxes are ticked, every face is exported twice. Different materials and textures on the front and back of a face is supported.
- If you do freeform uv mapping of a texture to multiple faces in sketchup and the uv coords are stretched or distorted in any way, sketchup will generate new textures (instead of using uv coords to distort the texture, it does the distortion in a software renderer and saves a new texture). One texture in a model can easily become hundreds or nearly identical textures after export. There is no way to avoid this (while still keeping texturing correct).
- Colourising textures isn't currently supported (uncolourised version is exported to the material file).
- Some models still have 1 or 2 bad texture distortions when there are over 300 or so distortioned textures. Only 2 test models I have from the sketchup warehouse are doing this. I'm looking into it. 


History
-------

1.0.0 - First release
1.0.1 - Materials inheritted from groups / components
1.1.0 - Major rewrite and functionality change. Config dialog added, code moved to modules, distorted textures handled.
 