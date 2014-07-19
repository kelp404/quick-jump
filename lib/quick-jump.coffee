QuickJumpView = require './quick-jump-view'

module.exports =
    editorSubscription: null

    activate: ->
        @editorSubscription = atom.workspaceView.eachEditorView (editorView) =>
            return if not editorView.attached or editorView.mini
            new QuickJumpView editorView
