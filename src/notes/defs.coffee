import {findDOMNode} from "react-dom"
import {Component, createElement} from "react"
import h from "react-hyperscript"
import T from "prop-types"

ArrowMarker = ({id, orient, size: sz, fill})->
  fill ?= 'black'
  sz ?= 2.5
  h 'marker', {
    id
    orient
    markerHeight: sz
    markerWidth: sz
    markerUnits: 'strokeWidth'
    refX:"0"
    refY:"0"
    viewBox:"-#{sz} -#{sz} #{sz*2} #{sz*2}"
  }, [
    h 'path', {
      d:"M 0,0 m -#{sz},-#{sz} L #{sz},0 L -#{sz},#{sz} Z"
      fill
    }
  ]

EndpointTick = ({id, fill, size: sz})->
  fill ?= 'black'
  sz ?= 2.5
  h 'marker', {
    id
    markerHeight: 2
    markerWidth: sz*2
    markerUnits: 'strokeWidth'
    refX: 0
    refY: 0
    viewBox:"-#{sz} -1 #{sz*2} 1"
  }, [
    h 'path', {
      d: "M -#{sz},0 L #{sz},0"
      fill: 'transparent'
      stroke: fill
    }
  ]

NoteDefs = ({fill, prefix})->
  prefix ?= ""
  h 'defs', [
    h ArrowMarker, {id: prefix+'arrow_start', orient: 270, fill}
    h ArrowMarker, {id: prefix+'arrow_end', orient: 90, fill}
    h EndpointTick, {id: prefix+'tick', fill}
  ]

export default NoteDefs
