{EditorView, View} = require 'atom'


module.exports =
class QuickJumpView extends View
    @content: ->
        @div class: 'select-list popover-list', =>
            @subview 'filterEditorView', new EditorView(mini: yes)

    initialize: (@editorView) ->
        {@editor} = @editorView
        @handleEvents()

    handleEvents: ->
        @editorView.command 'quick-jump:start', =>
            @editor.beginTransaction()
            @editorView.appendToLinesView @
            @setPosition()
            @filterEditorView.focus()
        @filterEditorView.preempt 'textInput', ({originalEvent}) =>
            text = originalEvent.data
            console.log text

    setPosition: ->
        {left, top} = @editorView.pixelPositionForScreenPosition @editor.getCursorScreenPosition()
        height = @outerHeight()
        potentialTop = top + @editorView.lineHeight
        @css
            left: left
            top: potentialTop
            bottom: 'inherit'
