import {createContext, useContext} from 'react'
import {StatefulComponent} from '@macrostrat/ui-components'
import {Node, Renderer, Force} from "labella"
import h from '@macrostrat/hyper'
import T from 'prop-types'

import {hasSpan} from './utils'
import {NoteShape} from './types'
import FlexibleNode from "./flexible-node"
import {ColumnLayoutProvider, ColumnContext} from '../context'

NoteLayoutContext = createContext()

buildColumnIndex = ->
  ###
  # Find out where on the X axis arrows,
  # etc. should plot to aviod overlaps
  ###
  heightTracker = []
  return (note)->
    colIx = 0
    # Get column that note should render in
    nPossibleCols = heightTracker.length+1
    for column in [0..nPossibleCols]
      heightTracker[column] ?= note.height
      if heightTracker[column] < note.height
        hy = note.top_height or note.height
        heightTracker[column] = hy
        colIx = column
        break
    return colIx

withinDomain = (scale)-> (d)->
  [start, end] = scale.domain()
  # end height greater than beginning
  end_height = d.top_height or d.height
  if start < end
    # Normal scale (e.g. height)
    return end_height >= start and d.height <= end
  else
    # Inverted scale (e.g. time)
    return end_height <= start and d.height >= end


class NoteLayoutProvider extends StatefulComponent
  @propTypes: {
    notes: T.arrayOf(NoteShape).isRequired
    width: T.number.isRequired
    paddingLeft: T.number
    # This needs to be a component technically
    noteComponent: T.func.isRequired
    forceOptions: T.object
  }
  @defaultProps: {
    paddingLeft: 60
    estimatedTextHeight: (note, width)->
      txt = note.note or ''
      return 12
  }
  @contextType: ColumnContext
  constructor: (props)->
    super props
    # State is very minimal to start
    {noteComponent} = @props
    @state = {
      notes: [],
      elementHeights: {},
      columnIndex: {}
      nodes: {}
      @generatePath
      @createNodeForNote
      noteComponent
    }

  render: ->
    {children, width} = @props
    h NoteLayoutContext.Provider, {value: @state}, (
      h ColumnLayoutProvider, {width}, children
    )

  computeContextValue: =>
    console.log "Computing context value"
    {width, paddingLeft} = @props
    # Clamp notes to within scale boundaries
    # (we could turn this off if desired)
    {pixelHeight, scaleClamped: scale} = @context

    forwardedValues = {
      # Forwarded values from column context
      # There may be a more elegant way to do this
      paddingLeft,
      scale
      width
      @registerHeight
      @generatePath
    }

    # Compute force layout
    renderer = new Renderer {
      direction: 'right'
      layerGap: paddingLeft
      nodeHeight: 5
    }

    @setState {
      renderer,
      forwardedValues...
    }

  savedRendererForWidth: (width)=>
    @_rendererIndex ?= {}
    @_rendererIndex[width] ?= new Renderer {
      direction: 'right'
      layerGap: width
      nodeHeight: 5
    }
    return @_rendererIndex[width]

  generatePath: (node, pixelOffset)=>
    {paddingLeft} = @props
    renderer = @savedRendererForWidth(paddingLeft-pixelOffset)
    try
      return renderer.generatePath(node)
    catch err
      return null

  createNodeForNote: (note)=>
    {notes, elementHeights} = @state
    {pixelHeight, scaleClamped: scale} = @context
    {id: noteID} = note
    pixelHeight = elementHeights[noteID] or 10
    padding = 5
    lowerHeight = scale(note.height)
    if hasSpan(note)
      upperHeight = scale(note.top_height)
      harr = [lowerHeight-padding,upperHeight+padding]
      if harr[0]-harr[1] > 0
        return new FlexibleNode harr, pixelHeight
    return new Node lowerHeight, pixelHeight

  computeForceLayout: (prevProps, prevState)=>
    {notes, nodes, elementHeights} = @state
    {pixelHeight, scale} = @context
    {width, paddingLeft, forceOptions} = @props

    return if notes.length == 0
    # Something is wrong...
    #return if elementHeights.length < notes.length
    # Return if we've already computed nodes
    v1 = Object.keys(nodes).length == notes.length
    prevState ?= {}
    v2 = elementHeights == prevState.elementHeights or []
    return if v1 and v2
    console.log "Computing force layout"

    force = new Force {
      minPos: 0,
      maxPos: pixelHeight
      nodeSpacing: 0
      forceOptions...
    }

    dataNodes = notes.map @createNodeForNote

    force.nodes(dataNodes).compute()
    nodes = force.nodes() or []
    nodesObj = {}
    for node, i in nodes
      note = notes[i]
      nodesObj[note.id] = node

    @updateState {nodes: {$set: nodesObj}}

  registerHeight: (id, height)=>
    return unless height?
    {elementHeights} = @state
    elementHeights[id] = height
    @updateState {elementHeights: {$set: elementHeights}}

  updateNotes: =>
    # We received a new set of notes from props
    {scaleClamped} = @context
    notes = @props.notes
      .filter withinDomain(scaleClamped)
      .sort (a,b)->a.height-b.height
    columnIndex = notes.map buildColumnIndex()
    @setState {notes, columnIndex}

  ###
  # Lifecycle methods
  ###
  componentDidMount: =>
    @_previousContext = null
    @updateNotes()
    @computeContextValue()

  componentDidUpdate: (prevProps, prevState)=>
    if @props.notes != prevProps.notes
      @updateNotes()

    # Update note component
    {noteComponent} = @props
    if noteComponent != prevProps.noteComponent
      @setState {noteComponent}
    @computeForceLayout.call(arguments...)
    return if @props.notes == prevProps.notes
    return if @context == @_previousContext
    @computeContextValue()
    @_previousContext = @context

NoteRect = (props)->
  {padding, width, rest...} = props
  padding ?= 5
  {pixelHeight} = useContext(ColumnContext)
  if not width?
    {width} = useContext(NoteLayoutContext)
  if isNaN(width)
    return null

  h 'rect', {
    width: width+2*padding
    height: pixelHeight
    transform: "translate(#{-padding},#{-padding})"
    rest...
  }

NoteUnderlay = ({fill, rest...})->
  fill ?= 'transparent'
  h NoteRect, {
    className: 'underlay'
    fill
    rest...
  }

export {NoteLayoutContext, NoteLayoutProvider, NoteRect, NoteUnderlay}
