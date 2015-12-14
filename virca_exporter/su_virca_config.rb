module VirCAConfig
  @@scale = 2.54
  @@copyTextures = true
  @@exportMeshes = true
  @@exportMaterials = true
  @@exportDefaultMaterials = true
  @@exportStyle = 1
  @@exportBackFaces = true
  @@exportFrontFaces = true
  @@convertXML = true
  @@exportRootFaces = true
  @@mergeComponents = true
  @@name = "CaptainAmerica1969"
  @@selectionOnly = true
  @@setEmissive = false
  @@enableDefLights = true
  @@enableCentring = true
  def self.scale; @@scale; end
  def self.copyTextures; @@copyTextures; end
  def self.exportMeshes; @@exportMeshes; end
  def self.exportMaterials; @@exportMaterials; end
  def self.exportDefaultMaterials; @@exportDefaultMaterials; end
  def self.exportStyle; @@exportStyle; end
  def self.exportBackFaces; @@exportBackFaces; end
  def self.exportFrontFaces; @@exportFrontFaces; end
  def self.exportRootFaces; @@exportRootFaces; end
  def self.mergeComponents; @@mergeComponents; end
  def self.convertXML; @@convertXML; end
  def self.name; @@name; end
  def self.selectionOnly; @@selectionOnly; end
  def self.setEmissive; @@setEmissive; end
  def self.enableDefLights; @@enableDefLights; end
  def self.enableCentring; @@enableCentring; end
  def self.scale=(v); @@scale=v; end
  def self.copyTextures=(v); @@copyTextures=v; end
  def self.exportMeshes=(v); @@exportMeshes=v; end
  def self.exportMaterials=(v); @@exportMaterials=v; end
  def self.exportDefaultMaterials=(v); @@exportDefaultMaterials=v; end
  def self.exportStyle=(v); @@exportStyle=v; end
  def self.exportBackFaces=(v); @@exportBackFaces=v; end
  def self.exportFrontFaces=(v); @@exportFrontFaces=v; end
  def self.exportRootFaces=(v); @@exportRootFaces=v; end
  def self.mergeComponents=(v); @@mergeComponents=v; end
  def self.convertXML=(v); @@convertXML=v; end
  def self.name=(v); @@name=v; end
  def self.selectionOnly=(v); @@selectionOnly=v; end
  def self.setEmissive=(v); @@setEmissive=v; end
  def self.enableDefLights=(v); @@enableDefLights=v; end
  def self.enableCentring=(v); @@enableCentring=v; end
  module Paths
    @@export = "C:\\Users\\Public\\Documents\\VirCA"
    @@converter = "c:\\OgreCommandLineTools\\OgreXMLConverter.exe"
    def self.export; @@export; end
    def self.converter; @@converter; end
    def self.export=(v); @@export=v; end
    def self.converter=(v); @@converter=v; end
  end
end
