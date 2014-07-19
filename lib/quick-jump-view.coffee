{EditorView, View} = require 'atom'


module.exports =
class QuickJumpView extends View
    @content: ->
        @div class: 'select-list popover-list', =>
            @subview 'filterEditorView', new EditorView(mini: yes)

    initialize: (@editorView) ->
        @css
            width: '50px'
            'min-width': '50px'
        {@editor} = @editorView
        @handleEvents()

    handleEvents: ->
        @editorView.command 'quick-jump:start', =>
            @editor.beginTransaction()
            @editorView.appendToLinesView @
            @setPosition()
            @filterEditorView.focus()

        @filterEditorView.on 'keydown', ({originalEvent}) =>
            return if originalEvent.metaKey # command + ?
            return if originalEvent.keyCode is 8 # back

            if originalEvent.keyCode is 27 # esc
                originalEvent.preventDefault()
                originalEvent.stopPropagation()
                @cancel()

            content = @filterEditorView.editor.getBuffer().lines[0]
            if content.length
                # there is a filter char
                originalEvent.preventDefault()
                originalEvent.stopPropagation()
                console.log "go #{originalEvent.keyCode}"

        @filterEditorView.editor.on 'contents-modified', =>
            # search targets by the filter char
            content = @filterEditorView.editor.getBuffer().lines[0]
            @searchTargets content

    cancel: ->
        @cancelled()
        @detach()

    cancelled: ->
        @filterEditorView.editor.setText('')
        @editor.abortTransaction()
        @editorView.focus()

    searchTargets: (keyword) ->
        if not keyword
            # clear targets
            return

        console.log "search: #{keyword}"

    setPosition: ->
        {left, top} = @editorView.pixelPositionForScreenPosition @editor.getCursorScreenPosition()
        height = @outerHeight()
        potentialTop = top + @editorView.lineHeight
        @css
            left: left
            top: potentialTop
            bottom: 'inherit'
