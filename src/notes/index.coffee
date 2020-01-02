import {Component, useContext} from "react"
import h from "../hyper"
import T from "prop-types"
import {NotesList} from './note'
import NoteDefs from './defs'
import {NoteShape} from './types'
import {useModelEditor} from '../context'
import {NoteLayoutProvider, NoteUnderlay} from './layout'
import {
  NoteEditor,
  NoteTextEditor,
  NoteEditorContext,
  NoteEditorProvider
} from './editor'
import {
  NewNotePositioner
} from './new'


NoteComponent = (props)->
  {visibility, note, onClick} = props
  text = note.note
  h 'p.note-label', {
    style: {visibility}
    onClick
  }, text

NoteComponent.propTypes = {
  onClick: T.func
  note: NoteShape.isRequired
}

CancelEditUnderlay = ->
  {setEditingNote} = useContext(NoteEditorContext)
  {confirmChanges} = useModelEditor()
  h NoteUnderlay, {
    onClick: ->
      setEditingNote(null)
  }

class NotesColumn extends Component
  @defaultProps: {
    type: 'log-notes'
    paddingLeft: 60
    inEditMode: false
    noteComponent: NoteComponent
    noteEditor: NoteTextEditor
    allowPositionEditing: false
    allowCreation: false
  }
  @propTypes: {
    notes: T.arrayOf(NoteShape).isRequired
    width: T.number.isRequired
    paddingLeft: T.number
    onUpdateNote: T.func
    onCreateNote: T.func
    onDeleteNote: T.func
    editingNote: NoteShape
    onEditNote: T.func
    inEditMode: T.bool
    noteComponent: T.elementType
    noteEditor: T.elementType
    allowPositionEditing: T.bool
  }
  render: ->
    {width,
     paddingLeft,
     transform,
     notes,
     inEditMode
     onUpdateNote
     onDeleteNote
     onCreateNote
     noteComponent
     noteEditor
     allowPositionEditing
    } = @props

    editHandler = onUpdateNote
    if not inEditMode
      editHandler = null

    innerWidth = width-paddingLeft

    h NoteLayoutProvider, {
      notes
      width: innerWidth
      paddingLeft
      noteComponent
    }, [
      h NoteEditorProvider, {
        inEditMode
        noteEditor
        onCreateNote
        onUpdateNote
        onDeleteNote
      }, [
        h 'g.section-log', {transform}, [
          h NoteDefs
          h CancelEditUnderlay
          h NotesList, {
            editHandler
            inEditMode
          }
          h NewNotePositioner
          h NoteEditor, {allowPositionEditing}
        ]
      ]
    ]

export {NotesColumn, NoteComponent, NoteTextEditor}
