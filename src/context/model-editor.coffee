import {createContext, useContext, useState, useEffect} from 'react'
import update from 'immutability-helper'
import h from 'react-hyperscript'

ModelEditorContext = createContext(null)

ModelEditorProvider = (props)->
  ###
  Context to assist with editing a model
  ###
  {model, logUpdates, children} = props
  logUpdates ?= false
  [editedModel, setState] = useState({model...})

  revertChanges = ->
    setState({model...})
  # Zero out edited model when model prop changes
  useEffect(revertChanges, [model])

  updateModel = (spec)->
    v = update(editedModel, spec)
    if logUpdates
      console.log(v)
    setState(v)

  hasChanges = ->
    model == editedModel

  value = {model, editedModel, updateModel, hasChanges, revertChanges}
  h ModelEditorContext.Provider, {value}, children

useModelEditor = ->
  useContext(ModelEditorContext)

export {ModelEditorProvider, ModelEditorContext, useModelEditor}
