{CompositeDisposable} = require 'atom'

module.exports = IrssiLogCleanup =
  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a
    # CompositeDisposable
    @subscriptions = new CompositeDisposable
    console.log("Activated irssi log cleanup plugin")

    # Register command that toggles this view
    @subscriptions.add  atom.commands.add 'atom-workspace',
                        'irssi-log-cleanup:cleanup': => @cleanup()
    @subscriptions.add  atom.commands.add 'atom-workspace',
                        'irssi-log-cleanup:clean-for-slack': => @cleanForSlack()

  deactivate: ->
    @subscriptions.dispose()
    
  cleanup: ->
    @doAFindAndReplace(/\n+\W+/g, (o) -> o.replace(" "))
    
  cleanForSlack: ->
    # first clean normally
    @cleanup()
    # atom's search doesn't understand ^ as "start of line," but instead
    # appears to think of it as "start of chunk." if you search by ^ it will
    # also find all of the whitespace that comes after \n at the end of a line.
    # therefore, avoid the chunks that contain a newline in order to get
    # only the matches that truly represent the start of what we humans
    # consider to be a line.
    @doAFindAndReplace(/^((?!\n))/g, (o) ->
      console.log(o)
      o.replace(">" + o.matchText)
    )
    
  doAFindAndReplace: (regex, forEachResult) ->
    console.log 'Transforming irssi log in buffer'
    
    # if there's a selection, use the selection; else use the entire buffer
    editor = atom.workspace.getActiveTextEditor()
    if editor
      selectionRange = {}
      selectedText = editor.getSelectedText()
      buffer = editor.getBuffer()
      if selectedText and selectedText.length > 0
        # use selected text
        console.log "Selected text is present, changing selection only"
        selectionRange = editor.getSelectedBufferRange()
      else
        # use whole buffer
        selectionRange = buffer.getRange()
        console.log "No selected text, changing entire buffer"
      
      buffer.backwardsScanInRange(regex, selectionRange, forEachResult)
      
    else
      console.log "Bailing out, can't reach text editor"
      