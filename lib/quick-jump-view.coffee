{$, EditorView, View} = require 'atom'


module.exports =
class QuickJumpView extends View
    @content: ->
        @div class: 'select-list popover-list quick-jump', =>
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
        # -------------------------------------------------
        # commands
        # -------------------------------------------------
        @editorView.command 'quick-jump:toggle', =>
            if @isWorking
                @cancel()
                return
            @editor.beginTransaction()
            @editorView.appendToLinesView @
            @setPosition()
            @filterEditorView.focus()
            @isWorking = yes

        @command 'quick-jump:cancel', =>
            @cancel()

        # -------------------------------------------------
        # events
        # -------------------------------------------------
        @filterEditorView.on 'focusout', =>
            # check focusout event is triggered by user
            @cancel() if @isWorking

        @filterEditorView.preempt 'textInput', =>
            # lock input when there is a char
            content = @filterEditorView.editor.getBuffer().lines[0]
            return no if content.length

        @filterEditorView.on 'keydown', ({originalEvent}) =>
            switch originalEvent.keyCode
                when 8 # back
                    @clearHighlight()
                    return
                when 13 # enter
                    originalEvent.preventDefault()
                    originalEvent.stopPropagation()
                    @cancel()
                    return

            content = @filterEditorView.editor.getBuffer().lines[0]
            if content.length
                # there is a filter char, set cursor to the taget.
                eventProcessed = no
                if originalEvent.keyCode is 9 # tab
                    # search next targets
                    eventProcessed = yes
                    bound = null
                    if not originalEvent.shiftKey
                        sorted = @targets.sort (a, b) -> a.row - b.row
                        bound =
                            top: sorted[0].row
                            bottom: sorted[sorted.length - 1].row
                    @targets = @searchTargets content, bound
                    @clearHighlight()
                    @highlightTargets @targets
                else
                    # go to the target.
                    index = @targetsIndexTable.indexOf String.fromCharCode(originalEvent.keyCode).toUpperCase()
                    eventProcessed = yes if index >= 0
                    if @targets[index]?
                        @cancel()
                        @gotoTarget @targets[index], originalEvent.metaKey
                if eventProcessed
                    originalEvent.preventDefault()
                    originalEvent.stopPropagation()
            else
                # press the char to search
                process.nextTick =>
                    # search targets by the filter char
                    content = @filterEditorView.editor.getBuffer().lines[0]
                    @targets = @searchTargets content
                    @clearHighlight()
                    @highlightTargets @targets

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

    searchTargets: (keyword, bound) ->
        """
        Search targets by the keyword near the cursor.
        @param keyword: {string} The keyword.
        @param bound: {object} The search bound.
            top: {int} The searchLineTop shoud less equal than this value.
            bottom: {int} The searchLineBottom should greater equal than this value.
        @return: {list} The point of targets.
            [{
                column: {int}
                row: {int}}
            }]
        """
        return[] if not keyword

        targets = []
        window.cc = @editor
        cursorRange = @editor.getSelectedBufferRange()
        buffer = @editor.getBuffer()
        for index in [0...buffer.lines.length] by 1
            ranSearch = 0
            searchLineTop = cursorRange.end.row - index
            searchLineBottom = cursorRange.end.row + index
            if searchLineTop >= 0 and index > 0 # search before cursor
                ranSearch++
                continue if searchLineTop > bound?.top
                targets.push x for x in @searchAtLine(keyword, buffer, searchLineTop)
            if searchLineBottom < buffer.lines.length # search after cursor
                ranSearch++
                continue if searchLineBottom < bound?.bottom
                targets.push x for x in @searchAtLine(keyword, buffer, searchLineBottom)
            break if not ranSearch or targets.length >= @targetsIndexTable.length
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

    gotoTarget: (target, isBehind) ->
        """
        Set cursor to the point.
        @param target: {object}
            column: {int}
            row: {int}
        @param isBehind: {bool} Is behind the target?
        """
        target.column++ if isBehind
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
