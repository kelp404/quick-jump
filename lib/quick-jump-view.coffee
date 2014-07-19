{$, EditorView, View} = require 'atom'


module.exports =
class QuickJumpView extends View
    @content: ->
        @div class: 'select-list popover-list', =>
            @subview 'filterEditorView', new EditorView(mini: yes)

    isWorking: no # QuickJumpView is visible. for focusout event.
    targets: []
    """
    The point objects.
    [{
        column: {int}
        row: {int}}
    }]
    """
    targetsIndexTable: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

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
            @isWorking = yes

        @filterEditorView.on 'keydown', ({originalEvent}) =>
            process.nextTick =>
                # search targets by the filter char
                content = @filterEditorView.editor.getBuffer().lines[0]
                @targets = @searchTargets content
                @highlightTargets @targets

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
                index = @targetsIndexTable.indexOf String.fromCharCode(originalEvent.keyCode).toUpperCase()
                if @targets[index]?
                    @cancel()
                    @gotoTarget @targets[index]

        @filterEditorView.on 'focusout', =>
            if @isWorking
                @cancel()

    cancel: ->
        """
        Hide quick jump view.
        """
        @clearHighlight()
        @isWorking = no
        @filterEditorView.editor.setText ''
        @editor.abortTransaction()
        @editorView.focus()
        @detach()

    searchTargets: (keyword) ->
        """
        Search targets by the keyword near the cursor.
        @param keyword: {string} The keyword.
        @return: {list} The point of targets.
            [{
                column: {int}
                row: {int}}
            }]
        """
        if not keyword
            @clearHighlight()
            return[]

        targets = []
        cursorRange = @editor.getSelection().getBufferRange()
        buffer = @editor.getBuffer()
        #column row
        for index in [0...buffer.lines.length] by 1
            ranSearch = 0
            searchLineTop = cursorRange.end.row - index
            searchLineBottom = cursorRange.end.row + index
            if searchLineTop >= 0 and index > 0 # search before cursor
                ranSearch++
                targets.push x for x in @searchAtLine(keyword, buffer, searchLineTop)
            if searchLineBottom < buffer.lines.length # search after cursor
                ranSearch++
                targets.push x for x in @searchAtLine(keyword, buffer, searchLineBottom)
            break if not ranSearch or targets.length >= 36
        targets

    searchAtLine: (keyword, buffer, line) ->
        """
        Search at the line of the editor's buffer by the keyword.
        @param keyword: {string} The search keyword.
        @param buffer: {buffer object} The buffer of the editor.
        @param line: {int} The line of the buffer.
        @return: {list} Target objects. [point{column: {int}, row: {int}}]
        """
        keyword = keyword.toLowerCase()
        for index in [0...buffer.lines[line].length] by 1 when buffer.lines[line][index].toLowerCase() is keyword
            column: index
            row: line

    clearHighlight: ->
        """
        Remove all highlights.
        """
        @editorView.find('.qj-highlight').remove()

    highlightTargets: (targets) ->
        """
        Highlight targets.
        @param targets: {list}
            [{
                column: {int}
                row: {int}}
            }]
        """
        for target, index in targets when index < @targetsIndexTable.length
            $element = $("<div class='qj-highlight'>#{@targetsIndexTable[index]}</div>")
            $element.css @editorView.pixelPositionForBufferPosition([target.row, target.column])
            @editorView.find('.scroll-view .overlayer:first').append $element

    gotoTarget: (target) ->
        """
        Set cursor to the point.
        @param target: {object}
            column: {int}
            row: {int}
        """
        @editor.setCursorBufferPosition target

    setPosition: ->
        """
        Set the position of the input box of quick jump.
        """
        {left, top} = @editorView.pixelPositionForScreenPosition @editor.getCursorScreenPosition()
        height = @outerHeight()
        potentialTop = top + @editorView.lineHeight
        @css
            left: left
            top: potentialTop
            bottom: 'inherit'
