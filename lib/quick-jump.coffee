QuickJumpView = require './quick-jump-view'

module.exports =
    editorSubscription: null
    quickJumpViews: []

    initialize: ->

    activate: ->
        @editorSubscription = atom.workspaceView.eachEditorView (editorView) =>
            return if not editorView.attached or editorView.mini
            view = new QuickJumpView editorView
            @quickJumpViews.push view

            editorView.on 'editor:will-be-removed', =>
                console.log 'remove'


    deactivate: ->
