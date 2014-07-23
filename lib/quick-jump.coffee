QuickJumpView = require './quick-jump-view'

module.exports =
    editorSubscription: null
    quickJumpViews: []

    activate: ->
        @editorSubscription = atom.workspaceView.eachEditorView (editorView) =>
            return if not editorView.attached or editorView.mini
            quickJumpView = new QuickJumpView editorView
            @quickJumpViews.push quickJumpView
            editorView.on 'editor:will-be-removed', =>
                quickJumpView.destroy()
                for view, index in @quickJumpViews when view is quickJumpView
                    @quickJumpViews.splice index, 1
                    break

    deactivate: ->
        @editorSubscription?.off()
        @editorSubscription = null
        @quickJumpViews.forEach (quickJumpView) -> quickJumpView.destroy()
        @quickJumpViews = []
