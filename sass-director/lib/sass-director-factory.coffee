SassDirectorView = require './sass-director-view'
{CompositeDisposable} = require 'atom'

fs = require 'fs'
path = require 'path'

module.exports =
class SassDirectorFactory
    # Single Factory instance
    factory: null
    SassDirectorView: null

    # Generator Variables
    root_path: ""
    manifest_files: []
    strip_list: [';', '@import', '\'', '\"']

    constructor: (state) ->
        @SassDirectorView = new SassDirectorView(state.sassDirectorViewState)
        return @factory if @factory isnt null
        # First Run
        @__buildPaths__()

    __buildPaths__: ->
        @root_path = atom.project.getPaths()[0]

    __getImports__: ->
        console.log 'Obtaining Imports now...'
        # Needs to exist local to function
        imports = []
        # Read each file from the @manifest_files
        for path in @manifest_files
            console.log('Path: ', path)
            buffer = fs.readFileSync path
            body = buffer.toString();
            lines = body.split('\n')
            imports = (line for line in lines when line.match(/^@import/gi) != null)
            for el in imports
                index = imports.indexOf(el)
                for strip in @strip_list
                    imports[index] = imports[index].split(strip).join('').trim()
        return imports

    addManifestFile: ->
        manifest_path = atom.workspace.getActiveEditor().getPath()
        shortname = manifest_path.split("/")[manifest_path.split("/").length - 1]

        if @manifest_files.indexOf(manifest_path) >= 0 and @manifest_files.length > 0
            # Notify user that file exists in watch already
            atom.confirm
                message: 'Manifest File already exists'
                detailedMessage: shortname
                buttons:
                    Dismiss: -> console.log "#{shortname} already exists in #{@manifest_files}"
        else if shortname.match(/(\.sass$)|(\.scss$)/gi) == null
            atom.confirm
                message: 'This is not a valid file'
                detailedMessage: shortname
                buttons:
                    Dismiss: -> console.log "#{shortname} is not a valid filetype"
        else
            @manifest_files.push(manifest_path)
            atom.confirm
                message: 'Added new Manifest File'
                detailedMessage: shortname
                buttons:
                    Dismiss: -> console.log "#{shortname} was added to the list of manifest files"

    generate: ->
        console.log "Begin Generating Sequence..."
        if @manifest_files.length == 0
            atom.confirm
                message: 'No Manifest Files were registered'
                buttons:
                    Dismiss: -> console.log "Abort Generate due to no manifest files logged"
            return false
        else
            imports = @__getImports__()
            console.log('Imports: ', imports)
