# SketchUp to VirCA Exporter 0.6b
# Written by Sándor Tarsoly (MTA SZTAKI)
# It is based on:
# - Sketchup Backface Highlighting Version 1.0.0 Written by Kojack
# - SketchUp to Ogre Exporter Version 1.3.4 Written by Bastien Bourineau
# VERSION 0.6b
# RELEASE NOTES
# - Forth and fifth arguments are added to specular values in materials
# VERSION 0.5b
# RELEASE NOTES
# - Export room to VirCA dotRoom format (old scene and scfg formats are removed)
# VERSION 0.4b
# RELEASE NOTES
# - Special VirCA version restriction is removed
# VERSION 0.3b
# RELEASE NOTES
# - Turn on/off the model centring function
# KNOWN ISSUES
# - sometimes textures are missed
# VERSION 0.2b
# RELEASE NOTES
# - The default Export Path is VirCA 0.2.363 or VirCA 0.2.763 Media rooms folder
# - At first run of the SketchUp to VirCA Exporter the VirCA 0.2.363 or 0.2.763 must be installed (or have to hack the su_virca_config.rb file 49-56 row :))
# - Paths (Export, Ogre XML Converter) are verified (if the path is not exist a dialog appears)
# - The Export destination is verified. If the destination folder or file is existed you get a warning.
# KNOWN ISSUES
# - sometimes textures are missed
#
# Sketchup Backface Highlighting Version 1.0.0
# Written by Kojack
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place - Suite 330, Boston, MA 02111-1307, USA, or go to
# http://www.gnu.org/copyleft/lesser.txt.

module VirCAExport
    @@tw = nil
    @@countTriangles = 0
    @@countVertices = 0
    @@countMaterials = 0
    @@countTextures = 0
    @@materialList = {}
    @@textures = []
    @@optionsDialog = nil
	@@getPos = []
	@@roomExport = nil
    
    module_function
    
    def extract_filename(s)
        i = s.rindex(/[:\/\\]/)
        if i
            s.slice(i+1..-1)
        else
            s
        end  
    end

    def remove_badchar(s)
        s = s.tr('(', '_')
        s = s.tr(')', '_')
        s = s.tr('*', '')
        s = s.tr('{', '_')
        s = s.tr('}', '_')
        s = s.tr('[', '_')
        s = s.tr(']', '_')
        s = s.tr('=', '')
        s = s.tr('?', '')
        s = s.tr('&', '')
        s = s.tr(':', '')
        s = s.tr('<', '_')
        s = s.tr(',', '_')
        s = s.tr('>', '_')
        s = s.tr('^', '_')
        s = s.tr('%', '_')
        s = s.tr('"', '_')
        s = s.tr('#', '_')
        s = s.tr(' ', '_')
        s = s.tr('/', '_')
        s = s.tr('\\', '_')
        s = s.tr('\'', '_')	
    end

    def append_paths(p,f)
        if p[-1,1] == "\\" or p[-1,1] == "/"
            p.gsub(/[\\]/, '/')+f
        else
            p.gsub(/[\\]/, '/')+"/"+f
        end
    end

    def exportDialog()
        load "virca_exporter/su_virca_config.rb"
        if @@optionsDialog == nil
            @@optionsDialog = UI::WebDialog.new("VirCA Exporter 0.6b Settings", true, "SketcUPVirCAExport", 720, 490, 250, 250, true);
            @@optionsDialog.set_file(Sketchup.find_support_file("su_virca_export.htm","plugins/virca_exporter"),nil)
			@@optionsDialog.set_size(720,490)
        end
        @@optionsDialog.show_modal {
            @@optionsDialog.execute_script("setExportOption(\"ExportName\",#{VirCAConfig.name.inspect})")
            @@optionsDialog.execute_script("setExportOption(\"ExportPath\",#{VirCAConfig::Paths.export.inspect})") 
			@@optionsDialog.execute_script("setExportOption(\"OgreXMLConverter\",#{VirCAConfig::Paths.converter.inspect})")
			@@optionsDialog.execute_script("setExportOptionCheckbox(\"CheckboxEmissiveSet\",#{VirCAConfig.setEmissive})")
			@@optionsDialog.execute_script("setExportOptionCheckbox(\"CheckboxLightsSet\",#{VirCAConfig.enableDefLights})")
			@@optionsDialog.execute_script("setExportOptionCheckbox(\"CheckboxCentring\",#{VirCAConfig.enableCentring})")
			@@optionsDialog.add_action_callback("on_exportModel") {|d,p| grabDialogData; saveConfig; checkSelection; checkExportPath; checkConverterPath; checkModelName; getPosition; modelCentring; setModelExport; export; modelRemove; d.close} 
			@@optionsDialog.add_action_callback("on_exportRoom") {|d,p| grabDialogData; saveConfig; checkSelection; checkExportPath; checkConverterPath; checkRoomName; getPosition; modelCentring; setRoomExport; writeDotRoom; export; modelRemove; d.close}
            @@optionsDialog.add_action_callback("on_cancel") {|d,p| d.close} 
        }
    end

    def getDialogCheckbox(checkbox)
        @@optionsDialog.execute_script("getExportOptionCheckbox(\"#{checkbox}\")")
        if @@optionsDialog.get_element_value("HiddenInput") == "true"
            true
        else
            false
        end
    end	
	
    def grabDialogData()
        if @@optionsDialog.visible?
			VirCAConfig.name = @@optionsDialog.get_element_value("ExportName")
            VirCAConfig::Paths.export = @@optionsDialog.get_element_value("ExportPath")
            VirCAConfig::Paths.converter = @@optionsDialog.get_element_value("OgreXMLConverter")
			VirCAConfig.setEmissive = getDialogCheckbox("CheckboxEmissiveSet")
			VirCAConfig.enableDefLights = getDialogCheckbox("CheckboxLightsSet")
			VirCAConfig.enableCentring = getDialogCheckbox("CheckboxCentring")
        end
    end

    def saveConfig()
        out = open(Sketchup.find_support_file("plugins")+"/virca_exporter/su_virca_config.rb", "w")
        out.print "module VirCAConfig\n"
        out.print "  @@scale = 2.54\n"
        out.print "  @@copyTextures = true\n"
        out.print "  @@exportMeshes = true\n"
        out.print "  @@exportMaterials = true\n"
        out.print "  @@exportDefaultMaterials = true\n"
        out.print "  @@exportStyle = 1\n"
        out.print "  @@exportBackFaces = true\n"
        out.print "  @@exportFrontFaces = true\n"
        out.print "  @@convertXML = true\n"
        out.print "  @@exportRootFaces = true\n"
        out.print "  @@mergeComponents = true\n"
        out.print "  @@name = #{VirCAConfig.name.inspect}\n"
        out.print "  @@selectionOnly = true\n"
		out.print "  @@setEmissive = #{VirCAConfig.setEmissive}\n"
		out.print "  @@enableDefLights = #{VirCAConfig.enableDefLights}\n"
		out.print "  @@enableCentring = #{VirCAConfig.enableCentring}\n"
        out.print "  def self.scale; @@scale; end\n"
        out.print "  def self.copyTextures; @@copyTextures; end\n"
        out.print "  def self.exportMeshes; @@exportMeshes; end\n"
        out.print "  def self.exportMaterials; @@exportMaterials; end\n"
        out.print "  def self.exportDefaultMaterials; @@exportDefaultMaterials; end\n"
        out.print "  def self.exportStyle; @@exportStyle; end\n"
        out.print "  def self.exportBackFaces; @@exportBackFaces; end\n"
        out.print "  def self.exportFrontFaces; @@exportFrontFaces; end\n"
        out.print "  def self.exportRootFaces; @@exportRootFaces; end\n"
        out.print "  def self.mergeComponents; @@mergeComponents; end\n"
        out.print "  def self.convertXML; @@convertXML; end\n"
        out.print "  def self.name; @@name; end\n"
        out.print "  def self.selectionOnly; @@selectionOnly; end\n"
		out.print "  def self.setEmissive; @@setEmissive; end\n"
		out.print "  def self.enableDefLights; @@enableDefLights; end\n"
		out.print "  def self.enableCentring; @@enableCentring; end\n"
        out.print "  def self.scale=(v); @@scale=v; end\n"
        out.print "  def self.copyTextures=(v); @@copyTextures=v; end\n"
        out.print "  def self.exportMeshes=(v); @@exportMeshes=v; end\n"
        out.print "  def self.exportMaterials=(v); @@exportMaterials=v; end\n"
        out.print "  def self.exportDefaultMaterials=(v); @@exportDefaultMaterials=v; end\n"
        out.print "  def self.exportStyle=(v); @@exportStyle=v; end\n"
        out.print "  def self.exportBackFaces=(v); @@exportBackFaces=v; end\n"
        out.print "  def self.exportFrontFaces=(v); @@exportFrontFaces=v; end\n"
        out.print "  def self.exportRootFaces=(v); @@exportRootFaces=v; end\n"
        out.print "  def self.mergeComponents=(v); @@mergeComponents=v; end\n"
        out.print "  def self.convertXML=(v); @@convertXML=v; end\n"
        out.print "  def self.name=(v); @@name=v; end\n"
        out.print "  def self.selectionOnly=(v); @@selectionOnly=v; end\n"
		out.print "  def self.setEmissive=(v); @@setEmissive=v; end\n"
		out.print "  def self.enableDefLights=(v); @@enableDefLights=v; end\n"
		out.print "  def self.enableCentring=(v); @@enableCentring=v; end\n"
        out.print "  module Paths\n"
        out.print "    @@export = #{VirCAConfig::Paths.export.inspect}\n"
        out.print "    @@converter = #{VirCAConfig::Paths.converter.inspect}\n"
        out.print "    def self.export; @@export; end\n"
        out.print "    def self.converter; @@converter; end\n"
		out.print "    def self.export=(v); @@export=v; end\n"
        out.print "    def self.converter=(v); @@converter=v; end\n"
        out.print "  end\n"
        out.print "end\n"
        out.close
    end
	
	def checkExportPath()
		if FileTest::directory?(VirCAConfig::Paths.export)
			puts "Ok, The Export Path is valid"
		else
			UI.messagebox('The Export Path is not valid.')
			abort("Failed, The Export Path is not valid")
		end
	end

	def checkConverterPath()
		if FileTest::exist?(VirCAConfig::Paths.converter)
			puts "Ok, The Ogre XML Converter Path is valid"
		else
			UI.messagebox('The Ogre XML Converter Path is not valid.')
			abort("Failed, The Ogre XML Converter Path is not valid")
		end
	end
	
	def getPosition()
		selection = Sketchup.active_model.selection
		selection_bb = Geom::BoundingBox.new
		selection.each {|e| selection_bb.add(e.bounds)} 
		@@getPos = Geom::Vector3d.new(selection_bb.center.vector_to(ORIGIN))
	end
	
	def modelCentring()
		if VirCAConfig.enableCentring
			selection = Sketchup.active_model.selection
			Sketchup.active_model.entities.transform_entities(@@getPos, selection.to_a )
		end
	end
	
	def modelRemove()
		if VirCAConfig.enableCentring
			selection = Sketchup.active_model.selection
			Sketchup.active_model.entities.transform_entities(@@getPos.reverse, selection.to_a )
		end
	end

	def setRoomExport()
		@@roomExport = true
	end
	
	def setModelExport()
		@@roomExport = false
	end

	def checkModelName()
		$meshespath = VirCAConfig::Paths.export + "\\" + VirCAConfig.name
		if FileTest::exist?(append_paths($meshespath, VirCAConfig.name + ".mesh"))
			$result = UI.messagebox(VirCAConfig.name + '.mesh is existed. Do you want to overwrite?', MB_YESNO)
			if $result == IDNO
				abort("Failed, #{VirCAConfig.name}.mesh is existed and the user does not want to overwrite.")
			end
		end		
	end

	def checkRoomName()
		if FileTest::directory?(VirCAConfig::Paths.export + "\\" + VirCAConfig.name)
			$result = UI.messagebox(VirCAConfig.name + ' room is existed. Do you want to overwrite?', MB_YESNO)
			if $result == IDNO
				abort("Failed, #{VirCAConfig.name} room is existed and the user does not want to overwrite.")
			end
		end		
	end

	def checkSelection()
		if VirCAConfig.selectionOnly
			selection = Sketchup.active_model.selection
			if selection.count == 0
				UI.messagebox "Nothing selected"
				abort("Failed, Nothing selected")
			end
        end
	end
	
    def collectFace(m, face, trans, handle, frontface, inherited_mat)
        index = nil
        (m.size).times {|i| if m[i][0]==handle then index = i end}
        if index
            m[index][1].push([face,trans,frontface, inherited_mat])
        else
            m.push([handle,[[face,trans,frontface, inherited_mat]]])
        end
    end
    
    def collectMaterials(matlist, ents, trans, inherited_mat, root)
        for e in ents
            case e
            when Sketchup::Face
                if (not root) or VirCAConfig.exportRootFaces
                    if VirCAConfig.exportFrontFaces
                        if e.material
                            mat = e.material
                            handle = @@tw.load(e,true)
                        else
                            if inherited_mat
                                mat = inherited_mat[0]
                                handle = @@tw.load(inherited_mat[1],true)
                            else
                                mat = nil
                                handle = 0
                            end
                        end
                        m = matlist[mat]
                        collectFace(m, e, trans, handle, true, if mat then nil else inherited_mat end)
                    end
                    if VirCAConfig.exportBackFaces
                        if e.back_material
                            mat = e.back_material
                            handle = @@tw.load(e,false)
                        else
                            if inherited_mat
                                mat = inherited_mat[0]
                                handle = @@tw.load(inherited_mat[1],false)
                            else
                                mat = nil
                                handle = 0
                            end
                        end
                        m = matlist[mat]
                        collectFace(m, e, trans, handle, false, if mat then nil else inherited_mat end)
                    end
                end
            when Sketchup::Group
                collectMaterials(matlist, e.entities, trans*e.transformation, if e.material then [e.material,e,e.transformation] else inherited_mat end, root)
            when Sketchup::ComponentInstance
                collectMaterials(matlist, e.definition.entities, trans*e.transformation, if e.material then [e.material,e,e.transformation] else inherited_mat end, false)
            end
        end
    end

	def writeDotRoom()
		$roompath = VirCAConfig::Paths.export + "\\" + VirCAConfig.name
		Dir::mkdir($roompath) unless FileTest::directory?($roompath)
		
		file_scene = open(append_paths($roompath, VirCAConfig.name+".room"),"w")
		file_scene.print "<?xml version=\"1.0\"?>\n"
		file_scene.print "<room name=\"#{VirCAConfig.name}\" version=\"1.0\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n"
		file_scene.print "\t<settings>\n"
		if VirCAConfig.enableDefLights		
			file_scene.print "\t\t<environment>\n"
			file_scene.print "\t\t\t<shader>RTSS</shader>\n"		
			file_scene.print "\t\t</environment>\n"			
		end
			file_scene.print "\t\t<pointer>\n"
			file_scene.print "\t\t\t<visibility>false</visibility>\n"
			file_scene.print "\t\t\t<crosshairs>true</crosshairs>\n"
			file_scene.print "\t\t\t<length>0</length>\n"
			file_scene.print "\t\t\t<offset>\n"
			file_scene.print "\t\t\t\t<x>0.0</x>\n"
			file_scene.print "\t\t\t\t<y>-20.0</y>\n"
			file_scene.print "\t\t\t\t<z>-75.0</z>\n"			
			file_scene.print "\t\t\t</offset>\n"
			file_scene.print "\t\t</pointer>\n"			
			file_scene.print "\t\t<boundaries>\n"
			file_scene.print "\t\t\t<xlimit>\n"
			file_scene.print "\t\t\t\t<min>-10000.0</min>\n"
			file_scene.print "\t\t\t\t<max>10000.0</max>\n"
			file_scene.print "\t\t\t</xlimit>\n"
			file_scene.print "\t\t\t<ylimit>\n"
			file_scene.print "\t\t\t\t<min>-10000.0</min>\n"
			file_scene.print "\t\t\t\t<max>10000.0</max>\n"
			file_scene.print "\t\t\t</ylimit>\n"
			file_scene.print "\t\t\t<zlimit>\n"
			file_scene.print "\t\t\t\t<min>-10000.0</min>\n"
			file_scene.print "\t\t\t\t<max>10000.0</max>\n"
			file_scene.print "\t\t\t</zlimit>\n"
			file_scene.print "\t\t</boundaries>\n"
			file_scene.print "\t\t<camera>\n"
			file_scene.print "\t\t\t<pose>\n"
			file_scene.print "\t\t\t\t<position>\n"
			file_scene.print "\t\t\t\t\t<x>0.0</x>\n"
			file_scene.print "\t\t\t\t\t<y>160.0</y>\n"
			file_scene.print "\t\t\t\t\t<z>0.0</z>\n"
			file_scene.print "\t\t\t\t</position>\n"
			file_scene.print "\t\t\t\t<orientation>\n"
			file_scene.print "\t\t\t\t\t<ypr>\n"
			file_scene.print "\t\t\t\t\t\t<yaw>0.0</yaw>\n"
			file_scene.print "\t\t\t\t\t\t<pitch>0.0</pitch>\n"
			file_scene.print "\t\t\t\t\t\t<roll>0.0</roll>\n"
			file_scene.print "\t\t\t\t\t</ypr>\n"
			file_scene.print "\t\t\t\t</orientation>\n"
			file_scene.print "\t\t\t</pose>\n"			
			file_scene.print "\t\t\t<clipping>\n"
			file_scene.print "\t\t\t\t<near>10.0</near>\n"
			file_scene.print "\t\t\t\t<far>100000.0</far>\n"
			file_scene.print "\t\t\t</clipping>\n"
			file_scene.print "\t\t\t<fov>45.0</fov>\n"
			file_scene.print "\t\t</camera>\n"			
			file_scene.print "\t</settings>\n"
			file_scene.print "\t<content>\n"
			file_scene.print "\t\t<node name=\"#{VirCAConfig.name}\">\n"
			file_scene.print "\t\t\t<pose>\n"
			file_scene.print "\t\t\t\t<position>\n"
			file_scene.print "\t\t\t\t\t<x>0.0</x>\n"
			file_scene.print "\t\t\t\t\t<y>0.0</y>\n"
			file_scene.print "\t\t\t\t\t<z>0.0</z>\n"
			file_scene.print "\t\t\t\t</position>\n"
			file_scene.print "\t\t\t\t<orientation>\n"
			file_scene.print "\t\t\t\t\t<ypr>\n"
			file_scene.print "\t\t\t\t\t\t<yaw>0.0</yaw>\n"
			file_scene.print "\t\t\t\t\t\t<pitch>0.0</pitch>\n"
			file_scene.print "\t\t\t\t\t\t<roll>0.0</roll>\n"
			file_scene.print "\t\t\t\t\t</ypr>\n"
			file_scene.print "\t\t\t\t</orientation>\n"
			file_scene.print "\t\t\t</pose>\n"
			file_scene.print "\t\t\t<entity>\n"
			file_scene.print "\t\t\t\t<meshFileName>#{VirCAConfig.name}.mesh</meshFileName>\n"
			file_scene.print "\t\t\t</entity>\n"
			file_scene.print "\t\t</node>\n"
		if VirCAConfig.enableDefLights				
			file_scene.print "\t\t<node name=\"LightSource1\">\n"
			file_scene.print "\t\t\t<pose>\n"
			file_scene.print "\t\t\t\t<position>\n"
			file_scene.print "\t\t\t\t\t<x>0.0</x>\n"
			file_scene.print "\t\t\t\t\t<y>0.0</y>\n"
			file_scene.print "\t\t\t\t\t<z>0.0</z>\n"
			file_scene.print "\t\t\t\t</position>\n"
			file_scene.print "\t\t\t\t<orientation>\n"
			file_scene.print "\t\t\t\t\t<ypr>\n"
			file_scene.print "\t\t\t\t\t\t<yaw>0.0</yaw>\n"
			file_scene.print "\t\t\t\t\t\t<pitch>0.0</pitch>\n"
			file_scene.print "\t\t\t\t\t\t<roll>0.0</roll>\n"
			file_scene.print "\t\t\t\t\t</ypr>\n"
			file_scene.print "\t\t\t\t</orientation>\n"
			file_scene.print "\t\t\t</pose>\n"
			file_scene.print "\t\t\t<light>\n"
			file_scene.print "\t\t\t\t<diffuse>\n"
			file_scene.print "\t\t\t\t\t<r>0.8</r>\n"
			file_scene.print "\t\t\t\t\t<g>0.8</g>\n"
			file_scene.print "\t\t\t\t\t<b>0.8</b>\n"
			file_scene.print "\t\t\t\t\t<a>1.0</a>\n"
			file_scene.print "\t\t\t\t</diffuse>\n"
			file_scene.print "\t\t\t\t<specular>\n"
			file_scene.print "\t\t\t\t\t<r>0.5</r>\n"
			file_scene.print "\t\t\t\t\t<g>0.5</g>\n"
			file_scene.print "\t\t\t\t\t<b>0.5</b>\n"
			file_scene.print "\t\t\t\t\t<a>1.0</a>\n"
			file_scene.print "\t\t\t\t</specular>\n"
			file_scene.print "\t\t\t\t<type>\n"
			file_scene.print "\t\t\t\t\t<directional>\n"
			file_scene.print "\t\t\t\t\t\t<direction>\n"
			file_scene.print "\t\t\t\t\t\t\t<x>1.0</x>\n"
			file_scene.print "\t\t\t\t\t\t\t<y>-1.0</y>\n"
			file_scene.print "\t\t\t\t\t\t\t<z>0.0</z>\n"		
			file_scene.print "\t\t\t\t\t\t</direction>\n"
			file_scene.print "\t\t\t\t\t</directional>\n"
			file_scene.print "\t\t\t\t</type>\n"		
			file_scene.print "\t\t\t</light>\n"
			file_scene.print "\t\t</node>\n"
			file_scene.print "\t\t<node name=\"LightSource2\">\n"
			file_scene.print "\t\t\t<pose>\n"
			file_scene.print "\t\t\t\t<position>\n"
			file_scene.print "\t\t\t\t\t<x>0.0</x>\n"
			file_scene.print "\t\t\t\t\t<y>0.0</y>\n"
			file_scene.print "\t\t\t\t\t<z>0.0</z>\n"
			file_scene.print "\t\t\t\t</position>\n"
			file_scene.print "\t\t\t\t<orientation>\n"
			file_scene.print "\t\t\t\t\t<ypr>\n"
			file_scene.print "\t\t\t\t\t\t<yaw>0.0</yaw>\n"
			file_scene.print "\t\t\t\t\t\t<pitch>0.0</pitch>\n"
			file_scene.print "\t\t\t\t\t\t<roll>0.0</roll>\n"
			file_scene.print "\t\t\t\t\t</ypr>\n"
			file_scene.print "\t\t\t\t</orientation>\n"
			file_scene.print "\t\t\t</pose>\n"
			file_scene.print "\t\t\t<light>\n"
			file_scene.print "\t\t\t\t<diffuse>\n"
			file_scene.print "\t\t\t\t\t<r>0.8</r>\n"
			file_scene.print "\t\t\t\t\t<g>0.8</g>\n"
			file_scene.print "\t\t\t\t\t<b>0.8</b>\n"
			file_scene.print "\t\t\t\t\t<a>1.0</a>\n"
			file_scene.print "\t\t\t\t</diffuse>\n"
			file_scene.print "\t\t\t\t<specular>\n"
			file_scene.print "\t\t\t\t\t<r>0.5</r>\n"
			file_scene.print "\t\t\t\t\t<g>0.5</g>\n"
			file_scene.print "\t\t\t\t\t<b>0.5</b>\n"
			file_scene.print "\t\t\t\t\t<a>1.0</a>\n"
			file_scene.print "\t\t\t\t</specular>\n"
			file_scene.print "\t\t\t\t<type>\n"
			file_scene.print "\t\t\t\t\t<directional>\n"
			file_scene.print "\t\t\t\t\t\t<direction>\n"
			file_scene.print "\t\t\t\t\t\t\t<x>-1.0</x>\n"
			file_scene.print "\t\t\t\t\t\t\t<y>-1.0</y>\n"
			file_scene.print "\t\t\t\t\t\t\t<z>0.0</z>\n"		
			file_scene.print "\t\t\t\t\t\t</direction>\n"
			file_scene.print "\t\t\t\t\t</directional>\n"
			file_scene.print "\t\t\t\t</type>\n"		
			file_scene.print "\t\t\t</light>\n"
			file_scene.print "\t\t</node>\n"
			file_scene.print "\t\t<node name=\"LightSource3\">\n"
			file_scene.print "\t\t\t<pose>\n"
			file_scene.print "\t\t\t\t<position>\n"
			file_scene.print "\t\t\t\t\t<x>0.0</x>\n"
			file_scene.print "\t\t\t\t\t<y>0.0</y>\n"
			file_scene.print "\t\t\t\t\t<z>0.0</z>\n"
			file_scene.print "\t\t\t\t</position>\n"
			file_scene.print "\t\t\t\t<orientation>\n"
			file_scene.print "\t\t\t\t\t<ypr>\n"
			file_scene.print "\t\t\t\t\t\t<yaw>0.0</yaw>\n"
			file_scene.print "\t\t\t\t\t\t<pitch>0.0</pitch>\n"
			file_scene.print "\t\t\t\t\t\t<roll>0.0</roll>\n"
			file_scene.print "\t\t\t\t\t</ypr>\n"
			file_scene.print "\t\t\t\t</orientation>\n"
			file_scene.print "\t\t\t</pose>\n"
			file_scene.print "\t\t\t<light>\n"
			file_scene.print "\t\t\t\t<diffuse>\n"
			file_scene.print "\t\t\t\t\t<r>0.8</r>\n"
			file_scene.print "\t\t\t\t\t<g>0.8</g>\n"
			file_scene.print "\t\t\t\t\t<b>0.8</b>\n"
			file_scene.print "\t\t\t\t\t<a>1.0</a>\n"
			file_scene.print "\t\t\t\t</diffuse>\n"
			file_scene.print "\t\t\t\t<specular>\n"
			file_scene.print "\t\t\t\t\t<r>0.5</r>\n"
			file_scene.print "\t\t\t\t\t<g>0.5</g>\n"
			file_scene.print "\t\t\t\t\t<b>0.5</b>\n"
			file_scene.print "\t\t\t\t\t<a>1.0</a>\n"
			file_scene.print "\t\t\t\t</specular>\n"
			file_scene.print "\t\t\t\t<type>\n"
			file_scene.print "\t\t\t\t\t<directional>\n"
			file_scene.print "\t\t\t\t\t\t<direction>\n"
			file_scene.print "\t\t\t\t\t\t\t<x>0.0</x>\n"
			file_scene.print "\t\t\t\t\t\t\t<y>-1.0</y>\n"
			file_scene.print "\t\t\t\t\t\t\t<z>1.0</z>\n"		
			file_scene.print "\t\t\t\t\t\t</direction>\n"
			file_scene.print "\t\t\t\t\t</directional>\n"
			file_scene.print "\t\t\t\t</type>\n"		
			file_scene.print "\t\t\t</light>\n"
			file_scene.print "\t\t</node>\n"
			file_scene.print "\t\t<node name=\"LightSource4\">\n"
			file_scene.print "\t\t\t<pose>\n"
			file_scene.print "\t\t\t\t<position>\n"
			file_scene.print "\t\t\t\t\t<x>0.0</x>\n"
			file_scene.print "\t\t\t\t\t<y>0.0</y>\n"
			file_scene.print "\t\t\t\t\t<z>0.0</z>\n"
			file_scene.print "\t\t\t\t</position>\n"
			file_scene.print "\t\t\t\t<orientation>\n"
			file_scene.print "\t\t\t\t\t<ypr>\n"
			file_scene.print "\t\t\t\t\t\t<yaw>0.0</yaw>\n"
			file_scene.print "\t\t\t\t\t\t<pitch>0.0</pitch>\n"
			file_scene.print "\t\t\t\t\t\t<roll>0.0</roll>\n"
			file_scene.print "\t\t\t\t\t</ypr>\n"
			file_scene.print "\t\t\t\t</orientation>\n"
			file_scene.print "\t\t\t</pose>\n"
			file_scene.print "\t\t\t<light>\n"
			file_scene.print "\t\t\t\t<diffuse>\n"
			file_scene.print "\t\t\t\t\t<r>0.8</r>\n"
			file_scene.print "\t\t\t\t\t<g>0.8</g>\n"
			file_scene.print "\t\t\t\t\t<b>0.8</b>\n"
			file_scene.print "\t\t\t\t\t<a>1.0</a>\n"
			file_scene.print "\t\t\t\t</diffuse>\n"
			file_scene.print "\t\t\t\t<specular>\n"
			file_scene.print "\t\t\t\t\t<r>0.5</r>\n"
			file_scene.print "\t\t\t\t\t<g>0.5</g>\n"
			file_scene.print "\t\t\t\t\t<b>0.5</b>\n"
			file_scene.print "\t\t\t\t\t<a>1.0</a>\n"
			file_scene.print "\t\t\t\t</specular>\n"
			file_scene.print "\t\t\t\t<type>\n"
			file_scene.print "\t\t\t\t\t<directional>\n"
			file_scene.print "\t\t\t\t\t\t<direction>\n"
			file_scene.print "\t\t\t\t\t\t\t<x>0.0</x>\n"
			file_scene.print "\t\t\t\t\t\t\t<y>-1.0</y>\n"
			file_scene.print "\t\t\t\t\t\t\t<z>-1.0</z>\n"		
			file_scene.print "\t\t\t\t\t\t</direction>\n"
			file_scene.print "\t\t\t\t\t</directional>\n"
			file_scene.print "\t\t\t\t</type>\n"		
			file_scene.print "\t\t\t</light>\n"
			file_scene.print "\t\t</node>\n"			
		end	
		file_scene.print "\t</content>\n"
		file_scene.print "</room>\n"
		file_scene.close
	end
	
    def writeMaterials(matlist)
		$texturespath = VirCAConfig::Paths.export + "\\" + VirCAConfig.name
		Dir::mkdir($texturespath) unless FileTest::directory?($texturespath)
		
        file_material = open(append_paths($texturespath, VirCAConfig.name+".material"),"w")
        for m,m2 in matlist
            if m
                i = 0
                for handles in m2
                    if handles[1].size > 0
                        @@countMaterials = @@countMaterials + 1
                        mat_name = remove_badchar(m.display_name) + if i > 0 then "_distort_#{i}" else "" end
                        file_material.print "material #{mat_name}\n"
                        file_material.print "{\n"
                        file_material.print "   technique\n"
                        file_material.print "   {\n"
                        file_material.print "      pass\n"
                        file_material.print "      {\n"
						# enable alpha only on png files since other tga or tiff format are most used without alpha
						# this limit the case of textures without alpha but with use_alpha enabled be sketchup
						textureext = ""
						if m.texture
						  textureext = File.extname(File.basename(m.texture.filename))
						end
						if (m.use_alpha? && (textureext == ".png") || (textureext == ".PNG")) || m.alpha < 1.0
							file_material.print "         scene_blend alpha_blend\n"
							file_material.print "         depth_check on\n"
							file_material.print "         depth_write off\n"
						end
                        if m.texture
                            #if extract_filename(m.texture.filename).index(/[ ]/)
                                #puts "Bad texture name: #{extract_filename(m.texture.filename)}"
                            #end
                            filename = extract_filename(remove_badchar(m.texture.filename))
                            ext_index = filename.rindex('.')
                            if ext_index
                                ext = filename.slice(ext_index+1..-1)
                                filename = filename.slice(0..ext_index-1)
                            else
                                ext = ""
                            end
                            filename = remove_badchar(File.basename(m.texture.filename))
                            file_material.print "         diffuse 1.0 1.0 1.0 #{m.alpha}\n"
							if VirCAConfig.setEmissive
								file_material.print "         emissive 1.0 1.0 1.0\n"
							else
								file_material.print "         emissive 0.0 0.0 0.0\n"
							end
                            file_material.print "         texture_unit\n"
                            file_material.print "         {\n"
                            file_material.print "            texture #{remove_badchar(filename)}\n"
                            file_material.print "         }\n"
                            if VirCAConfig.copyTextures
                                @@countTextures = @@countTextures + 1
                                if handles[1][0][3]
                                    t = @@tw.write handles[1][0][3][1], append_paths($texturespath, filename)
                                else
                                    t = @@tw.write handles[1][0][0], handles[1][0][2],  append_paths($texturespath, filename)
                                end
                            end
                        else
                            file_material.print "         diffuse #{m.color.red/255.0} #{m.color.green/255.0} #{m.color.blue/255.0} #{m.alpha}\n"
                            file_material.print "         ambient #{m.color.red/255.0} #{m.color.green/255.0} #{m.color.blue/255.0} #{m.alpha}\n"
							file_material.print "         specular 0.2 0.2 0.2 1.0 50\n"
							if VirCAConfig.setEmissive
								file_material.print "         emissive #{m.color.red/255.0} #{m.color.green/255.0} #{m.color.blue/255.0} #{m.alpha}\n"
							else
								file_material.print "         emissive 0.0 0.0 0.0\n"
							end
                        end
                        file_material.print "      }\n"
                        file_material.print "   }\n"
                        file_material.print "}\n\n"
                    end
                    i=i+1
                end
            end
        end
        if matlist[nil] and VirCAConfig.exportDefaultMaterials
            @@countMaterials = @@countMaterials + 2
            if matlist[nil][0][1].size > 0
                file_material.print "material SketchupDefault\n"
                file_material.print "{\n"
                file_material.print "   technique\n"
                file_material.print "   {\n"
                file_material.print "      pass\n"
                file_material.print "      {\n"
                colour = Sketchup.active_model.rendering_options["FaceFrontColor"]
                file_material.print "         diffuse #{colour.red/255.0} #{colour.green/255.0} #{colour.blue/255.0}\n"
                file_material.print "         ambient #{colour.red/255.0} #{colour.green/255.0} #{colour.blue/255.0}\n"
				file_material.print "         specular 0.2 0.2 0.2 1.0 50\n"
				if VirCAConfig.setEmissive
					file_material.print "         emissive #{colour.red/255.0} #{colour.green/255.0} #{colour.blue/255.0}\n"
				else
					file_material.print "         emissive 0.0 0.0 0.0\n"
                end
				file_material.print "      }\n"
                file_material.print "   }\n"
                file_material.print "}\n\n"
                file_material.print "material SketchupDefault_Back\n"
                file_material.print "{\n"
                file_material.print "   technique\n"
                file_material.print "   {\n"
                file_material.print "      pass\n"
                file_material.print "      {\n"
                colour = Sketchup.active_model.rendering_options["FaceBackColor"]
                file_material.print "         diffuse #{colour.red/255.0} #{colour.green/255.0} #{colour.blue/255.0}\n"
                file_material.print "         ambient #{colour.red/255.0} #{colour.green/255.0} #{colour.blue/255.0}\n"
				file_material.print "         specular 0.2 0.2 0.2 1.0 50\n"
				if VirCAConfig.setEmissive
					file_material.print "         emissive #{colour.red/255.0} #{colour.green/255.0} #{colour.blue/255.0}\n"
				else
					file_material.print "         emissive 0.0 0.0 0.0\n"
                end
                file_material.print "      }\n"
                file_material.print "   }\n"
                file_material.print "}\n"
            end
        end
        file_material.close
    end
	
    def exportFaces(matlist)
		$meshespath = VirCAConfig::Paths.export + "\\" + VirCAConfig.name
		Dir::mkdir($meshespath) unless FileTest::directory?($meshespath)
		
        out = open(append_paths($meshespath, VirCAConfig.name + ".mesh.xml"), "w")
        out.print "<mesh>\n"
        out.print "   <submeshes>\n"
        for m,m2 in matlist
            if m or VirCAConfig.exportDefaultMaterials
                i = 0
                for handles in m2
                    if handles[1].size > 0
                        if m
                            mat_name = remove_badchar(m.display_name) + if i > 0 then "_distort_#{i}" else "" end
                            has_texture = m.texture != nil
                        else 
                            mat_name = "SketchupDefault"
                            has_texture = nil
                        end
                        meshes = []
                        tri_count = 0
                        vertex_count = 0
                        for face in handles[1]
                            mesh = face[0].mesh 7
                            # mesh = mesh2.transform face[1]
                            mirrored = face[1].xaxis.cross(face[1].yaxis).dot(face[1].zaxis) < 0
                            meshes.push([mesh,mirrored,face[0],face[1],face[2]])
                            tri_count = tri_count + mesh.count_polygons
                            vertex_count = vertex_count + mesh.count_points
                        end
                        @@countTriangles = @@countTriangles + tri_count
                        @@countVertices = @@countVertices + vertex_count
                        startindex = 0
                        out.print "      <submesh material = \"#{mat_name}\" usesharedvertices=\"false\" "
                        if vertex_count<65537 
                            out.print "use32bitindexes=\"false\">\n"
                        else
                            out.print "use32bitindexes=\"true\">\n"
                        end
                        out.print "         <faces count=\"#{tri_count}\">\n"
                        for mesh in meshes
                            for poly in mesh[0].polygons
                                v1 = (poly[0]>=0?poly[0]:-poly[0])+startindex
                                v2 = (poly[1]>=0?poly[1]:-poly[1])+startindex
                                v3 = (poly[2]>=0?poly[2]:-poly[2])+startindex
                                if mesh[1] == mesh[4]
                                    out.print "            <face v1=\"#{v2-1}\" v2=\"#{v1-1}\" v3=\"#{v3-1}\" />\n"
                                else
                                    out.print "            <face v1=\"#{v1-1}\" v2=\"#{v2-1}\" v3=\"#{v3-1}\" />\n"
                                end
                            end
                            startindex = startindex + mesh[0].count_points
                        end
                        out.print "         </faces>\n"
                        out.print "         <geometry vertexcount=\"#{vertex_count}\">\n"
                        out.print "            <vertexbuffer positions=\"true\" normals=\"true\" colours_diffuse=\"false\" "
                        if has_texture 
                            out.print "texture_coords=\"1\" texture_coord_dimensions_0=\"2\""
                        end
                        out.print " >\n"

                        for mesh in meshes
                            matrix = mesh[3]
                            #matrix = Geom::Transformation.new
                            for p in (1..mesh[0].count_points)
                                pos = (matrix*mesh[0].point_at(p)).to_a
                                norm = (matrix*mesh[0].normal_at(p)).to_a
                                out.print "               <vertex>\n"
                                out.print "                  <position x=\"#{pos[0]*VirCAConfig.scale}\" y=\"#{pos[2]*VirCAConfig.scale}\" z=\"#{pos[1]*-VirCAConfig.scale}\" />\n"
                                if mesh[4]
                                    out.print "                  <normal x=\"#{norm[0]}\" y=\"#{norm[2]}\" z=\"#{-norm[1]}\" />\n"
                                else
                                    out.print "                  <normal x=\"#{-norm[0]}\" y=\"#{-norm[2]}\" z=\"#{norm[1]}\" />\n"
                                end
                                if has_texture
                                    if (mesh[2].material and mesh[4]) or (mesh[2].back_material and not mesh[4])
                                        texsize = Geom::Point3d.new(1, 1, 1)
                                    else
                                        texsize = Geom::Point3d.new(m.texture.width, m.texture.height, 1)
                                    end
                                    uvhelp = mesh[2].get_UVHelper true, true, @@tw
                                    #uv = [mesh[0].uv_at(p,1).x/texsize.x, mesh[0].uv_at(p,1).y/texsize.y, mesh[0].uv_at(p,1).z/texsize.z]
                                    #uv = [m.uv_at(p,1).x*1.0, m.uv_at(p,1).y*1.0, m.uv_at(p,1).z*1.0]
                                    if mesh[4]
                                        uv3d = uvhelp.get_front_UVQ mesh[0].point_at(p)
                                    else
                                        uv3d = uvhelp.get_back_UVQ mesh[0].point_at(p)
                                    end
                                    #uv3d = [mesh[0].uv_at(p,1).x, mesh[0].uv_at(p,1).y, mesh[0].uv_at(p,1).z]
                                    #out.print "                  <texcoord u=\"#{uv[0]}\" v=\"#{-uv[1]+1}\" />\n"
                                    out.print "                  <texcoord u=\"#{uv3d[0]/texsize.x}\" v=\"#{-uv3d[1]/texsize.y+1}\" />\n"
                                end
                                    out.print "               </vertex>\n"
                            end
                        end
                        out.print "            </vertexbuffer>\n"
                        out.print "         </geometry>\n"
                        out.print "      </submesh>\n"
                    end
                    i = i + 1
                end
            end
        end
        out.print "   </submeshes>\n"
        out.print "</mesh>\n"
        out.close
    end

    def export()
        @@countTriangles = 0
        @@countVertices = 0
        @@countMaterials = 0
        @@countTextures = 0
        @@materialList = {}
        @@textures = []
        @@tw = Sketchup.create_texture_writer
		
        tempface = Sketchup.active_model.entities.add_face(Geom::Point3d.new(23456,23456,23456), Geom::Point3d.new(23456,23457,23456), Geom::Point3d.new(23457,23456,23456))
        for m in Sketchup.active_model.materials
            tempface.material = m
            @@materialList[m] = [[@@tw.load(tempface,true),[]]]
        end
        @@materialList[nil] = [[0,[]]]
        Sketchup.active_model.entities.erase_entities tempface.edges
        puts "Collecting materials"
        if VirCAConfig.selectionOnly
            selection = Sketchup.active_model.selection
            if selection.count == 0
                UI.messagebox "Nothing selected"
                @@tw = nil
                @@materialList = nil
                @@textures = nil
                return
            end
        else
            selection = Sketchup.active_model.entities
        end
        collectMaterials(@@materialList, selection, Geom::Transformation.new, nil, true)
        if VirCAConfig.exportMaterials
            writeMaterials(@@materialList)
        end
        if VirCAConfig.exportMeshes
            exportFaces(@@materialList)
        end
        if VirCAConfig.convertXML
			system(VirCAConfig::Paths.converter + " " + "\"" + append_paths(VirCAConfig::Paths.export + "\\" + VirCAConfig.name, VirCAConfig.name+".mesh.xml") + "\"")
        end
        @@tw = nil
        @@materialList = nil
        @@textures = nil
        puts "Triangles = #{@@countTriangles}\nVertices = #{@@countVertices}\nMaterials = #{@@countMaterials}\nTextures = #{@@countTextures}"

		UI.messagebox('Export is finished!')
	end
end

menu = UI.menu "Plugins";
menu.add_separator
menu.add_item( "Export to VirCA") {VirCAExport.exportDialog}
