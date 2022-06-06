// THEOplayerRCTView.swift

import Foundation
import THEOplayerSDK

let ADD_TRACK: Int = 0
let REMOVE_TRACK: Int = 1
let ADD_CUE: Int = 0
let REMOVE_CUE: Int = 1


class THEOplayerRCTViewEventHandler {
    // MARK: Members
    private weak var player: THEOplayer?
    private var currentPresentationMode = PresentationMode.inline // TheoPlayer's initial presentationMode
        
    // MARK: Events
    var onNativePlay: RCTDirectEventBlock?
    var onNativePause: RCTDirectEventBlock?
    var onNativeSourceChange: RCTDirectEventBlock?
    var onNativeLoadStart: RCTDirectEventBlock?
    var onNativeReadyStateChange: RCTDirectEventBlock?
    var onNativeDurationChange: RCTDirectEventBlock?
    var onNativeProgress: RCTBubblingEventBlock?
    var onNativeTimeUpdate: RCTBubblingEventBlock?
    var onNativePlaying: RCTDirectEventBlock?
    var onNativeSeeking: RCTDirectEventBlock?
    var onNativeSeeked: RCTDirectEventBlock?
    var onNativeEnded: RCTDirectEventBlock?
    var onNativeError: RCTDirectEventBlock?
    var onNativeLoadedData: RCTDirectEventBlock?
    var onNativeLoadedMetadata: RCTDirectEventBlock?
    var onNativeFullscreenPlayerWillPresent: RCTDirectEventBlock?
    var onNativeFullscreenPlayerDidPresent: RCTDirectEventBlock?
    var onNativeFullscreenPlayerWillDismiss: RCTDirectEventBlock?
    var onNativeFullscreenPlayerDidDismiss: RCTDirectEventBlock?
    var onNativeTextTrackListEvent: RCTDirectEventBlock?
    var onNativeTextTrackEvent: RCTDirectEventBlock?
    
    // MARK: player Listeners
    private var playListener: EventListener?
    private var pauseListener: EventListener?
    private var sourceChangeListener: EventListener?
    private var loadStartListener: EventListener?
    private var readyStateChangeListener: EventListener?
    private var durationChangeListener: EventListener?
    private var progressListener: EventListener?
    private var timeUpdateListener: EventListener?
    private var playingListener: EventListener?
    private var seekingListener: EventListener?
    private var seekedListener: EventListener?
    private var endedListener: EventListener?
    private var errorListener: EventListener?
    private var loadedDataListener: EventListener?
    private var loadedMetadataListener: EventListener?
    private var presentationModeChangeListener: EventListener?
    
    // MARK: textTrackList Listeners
    private var addTrackListener: EventListener?
    private var removeTrackListener: EventListener?
    
    // MARK: textTrack listeners (attached dynamically to new texttracks)
    private var addCueListeners: [Int:EventListener] = [:]
    private var removeCueListeners: [Int:EventListener] = [:]
    
    
    // MARK: - Initialisation / deinitialisation
    deinit {
        // detach listeners
        self.dettachListeners()
    }
    
    // MARK: - player setup / breakdown
    func setPlayer(_ player: THEOplayer) {
        self.player = player;
        
        // attach listeners
        self.attachListeners()
    }
    
    private func attachListeners() {
        self.attachPlayerListeners()
        self.attachTextTrackListListeners()
    }
    
    private func dettachListeners() {
        self.dettachPlayerListeners()
        self.dettachTextTrackListListeners()
    }
    
    // MARK: - attach/dettach player Listeners
    private func attachPlayerListeners() {
        guard let player = self.player else {
            return
        }
        
        // PLAY
        self.playListener = player.addEventListener(type: PlayerEventTypes.PLAY) { [weak self] event in
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received PLAY event from THEOplayer") }
            if let forwardedPlayEvent = self?.onNativePlay {
                forwardedPlayEvent([:])
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] Play listener attached to THEOplayer") }
        
        // PAUSE
        self.pauseListener = player.addEventListener(type: PlayerEventTypes.PAUSE) { [weak self] event in
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received PAUSE event from THEOplayer") }
            if let forwardedPauseEvent = self?.onNativePause {
                forwardedPauseEvent([:])
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] Pause listener attached to THEOplayer") }
        
        // SOURCE_CHANGE
        self.sourceChangeListener = player.addEventListener(type: PlayerEventTypes.SOURCE_CHANGE) { [weak self] event in
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received SOURCE_CHANGE event from THEOplayer") }
            if let forwardedSourceChangeEvent = self?.onNativeSourceChange {
                forwardedSourceChangeEvent([:])
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] SourceChange listener attached to THEOplayer") }
        
        // LOAD_START
        self.loadStartListener = player.addEventListener(type: PlayerEventTypes.LOAD_START) { [weak self] event in
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received LOAD_START event from THEOplayer") }
            if let forwardedLoadStartEvent = self?.onNativeLoadStart {
                forwardedLoadStartEvent([:])
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] LoadStart listener attached to THEOplayer") }
        
        // READY_STATE_CHANGE
        self.readyStateChangeListener = player.addEventListener(type: PlayerEventTypes.READY_STATE_CHANGE) { [weak self] event in
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received READY_STATE_CHANGE event from THEOplayer") }
            if let forwardedReadyStateChangeEvent = self?.onNativeReadyStateChange {
                forwardedReadyStateChangeEvent(["readyState": event.readyState.rawValue])
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] ReadyStateChange listener attached to THEOplayer") }
        
        // DURATION_CHANGE
        self.durationChangeListener = player.addEventListener(type: PlayerEventTypes.DURATION_CHANGE) { [weak self] event in
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received DURATION_CHANGE event from THEOplayer") }
            if let forwardedDurationChangeEvent = self?.onNativeDurationChange {
                forwardedDurationChangeEvent(
                    [
                        "duration": event.duration ?? 0.0
                    ]
                )
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] DurationChange listener attached to THEOplayer") }
        
        // PROGRESS
        self.progressListener = player.addEventListener(type: PlayerEventTypes.PROGRESS) { [weak self] event in
            //if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received PROGRESS event from THEOplayer") }
            if let forwardedProgressEvent = self?.onNativeProgress {
                player.requestSeekable(completionHandler: { timeRanges, error in
                    var seekable: [[String:Double]] = []
                    timeRanges?.forEach({ timeRange in
                        seekable.append(
                            [
                                "start": timeRange.start * 1000,            // sec -> msec
                                "end": timeRange.end * 1000                 // sec -> msec
                            ]
                        )
                    })
                    forwardedProgressEvent(
                        [
                            "seekable":seekable
                        ]
                    )
                })
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] Progress listener attached to THEOplayer") }
        
        // TIME_UPDATE
        self.timeUpdateListener = player.addEventListener(type: PlayerEventTypes.TIME_UPDATE) { [weak self] event in
            //if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received TIME_UPDATE event from THEOplayer") }
            if let forwardedTimeUpdateEvent = self?.onNativeTimeUpdate {
                let currentTime = event.currentTime * 1000                                                          // sec -> msec
                let currentProgramDateTime = (event.currentProgramDateTime?.timeIntervalSince1970 ?? 0.0) * 1000    // sec -> msec
                forwardedTimeUpdateEvent(
                    [
                        "currentTime": currentTime,
                        "currentProgramDateTime": currentProgramDateTime
                    ]
                )
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] TimeUpdate listener attached to THEOplayer") }
        
        // PLAYING
        self.playingListener = player.addEventListener(type: PlayerEventTypes.PLAYING) { [weak self] event in
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received PLAYING event from THEOplayer") }
            if let forwardedPlayingEvent = self?.onNativePlaying {
                forwardedPlayingEvent([:])
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] Playing listener attached to THEOplayer") }
        
        // SEEKING
        self.seekingListener = player.addEventListener(type: PlayerEventTypes.SEEKING) { [weak self] event in
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received SEEKING event from THEOplayer") }
            if let forwardedSeekingEvent = self?.onNativeSeeking {
                forwardedSeekingEvent([:])
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] Seeking listener attached to THEOplayer") }
        
        // SEEKED
        self.timeUpdateListener = player.addEventListener(type: PlayerEventTypes.SEEKED) { [weak self] event in
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received SEEKED event from THEOplayer") }
            if let forwardedSeekedEvent = self?.onNativeSeeked {
                forwardedSeekedEvent([:])
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] Seeked listener attached to THEOplayer") }
        
        // ENDED
        self.endedListener = player.addEventListener(type: PlayerEventTypes.ENDED) { [weak self] event in
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received ENDED event from THEOplayer") }
            if let forwardedEndedEvent = self?.onNativeEnded {
                forwardedEndedEvent([:])
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] Ended listener attached to THEOplayer") }
        
        // ERROR
        self.errorListener = player.addEventListener(type: PlayerEventTypes.ERROR) { [weak self] event in
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received ERROR event from THEOplayer") }
            if let forwardedErrorEvent = self?.onNativeError,
               let errorObject = event.errorObject
            {
                let errorCodeString = String(describing: errorObject.code)
                let errorCodeMessage = errorObject.message
                forwardedErrorEvent(
                    [
                        "error": [
                            "errorCode":errorCodeString,
                            "errorMessage":errorCodeMessage
                        ]
                    ]
                )
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] Error listener attached to THEOplayer") }
        
        // LOADED_DATA
        self.loadedDataListener = player.addEventListener(type: PlayerEventTypes.LOADED_DATA) { [weak self] event in
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received LOADED_DATA event from THEOplayer") }
            if let forwardedLoadedDataEvent = self?.onNativeLoadedData {
                forwardedLoadedDataEvent([:])
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] LoadedData listener attached to THEOplayer") }
        
        // LOADED_META_DATA
        self.loadedMetadataListener = player.addEventListener(type: PlayerEventTypes.LOADED_META_DATA) { [weak self] event in
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received LOADED_META_DATA event from THEOplayer") }
            if let forwardedLoadedMetadataEvent = self?.onNativeLoadedMetadata {
                let metadata = THEOplayerRCTMetadataAggregator.aggregateMetadata(player: player)
                print(metadata)
                forwardedLoadedMetadataEvent(metadata)
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] LoadedMetadata listener attached to THEOplayer") }
        
        // PRESENTATION_MODE_CHANGE
        self.presentationModeChangeListener = player.addEventListener(type: PlayerEventTypes.PRESENTATION_MODE_CHANGE) { [weak self] event in
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received PRESENTATION_MODE_CHANGE event from THEOplayer") }
            if event.presentationMode != self?.currentPresentationMode {
                // entering fullscreen
                if event.presentationMode == .fullscreen ,
                   let forwardedFullscreenPlayerWillPresentEvent = self?.onNativeFullscreenPlayerWillPresent {
                    forwardedFullscreenPlayerWillPresentEvent([:])
                }
                if event.presentationMode == .fullscreen,
                   let forwardedFullscreenPlayerDidPresentEvent = self?.onNativeFullscreenPlayerDidPresent {
                    forwardedFullscreenPlayerDidPresentEvent([:])
                }
                // exiting fullscreen
                if self?.currentPresentationMode == .fullscreen,
                   let forwardedFullscreenPlayerWillDismissEvent = self?.onNativeFullscreenPlayerWillDismiss {
                    forwardedFullscreenPlayerWillDismissEvent([:])
                }
                if self?.currentPresentationMode == .fullscreen,
                   let forwardedFullscreenPlayerDidDismissEvent = self?.onNativeFullscreenPlayerDidDismiss {
                    forwardedFullscreenPlayerDidDismissEvent([:])
                }
                self?.currentPresentationMode = event.presentationMode
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] PresentationModeChange listener attached to THEOplayer") }
    }
    
    private func dettachPlayerListeners() {
        guard let player = self.player else {
            return
        }
        
        // PLAY
        if let playListener = self.playListener {
            player.removeEventListener(type: PlayerEventTypes.PLAY, listener: playListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] Play listener dettached from THEOplayer") }
        }
        
        // PAUSE
        if let pauseListener = self.pauseListener {
            player.removeEventListener(type: PlayerEventTypes.PAUSE, listener: pauseListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] Pause listener dettached from THEOplayer") }
        }
        
        // SOURCE_CHANGE
        if let sourceChangeListener = self.sourceChangeListener {
            player.removeEventListener(type: PlayerEventTypes.SOURCE_CHANGE, listener: sourceChangeListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] SourceChange listener dettached from THEOplayer") }
        }
        
        // LOAD_START
        if let loadStartListener = self.loadStartListener {
            player.removeEventListener(type: PlayerEventTypes.LOAD_START, listener: loadStartListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] LoadStart listener dettached from THEOplayer") }
        }
        
        // READY_STATE_CHANGE
        if let readyStateChangeListener = self.readyStateChangeListener {
            player.removeEventListener(type: PlayerEventTypes.READY_STATE_CHANGE, listener: readyStateChangeListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] ReadyStateChange listener dettached from THEOplayer") }
        }
        
        // DURATION_CHANGE
        if let durationChangeListener = self.durationChangeListener {
            player.removeEventListener(type: PlayerEventTypes.DURATION_CHANGE, listener: durationChangeListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] DurationChange listener dettached from THEOplayer") }
        }
        
        // PROGRESS
        if let progressListener = self.progressListener {
            player.removeEventListener(type: PlayerEventTypes.PROGRESS, listener: progressListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] Progress listener dettached from THEOplayer") }
        }
        
        // TIME_UPDATE
        if let timeUpdateListener = self.timeUpdateListener {
            player.removeEventListener(type: PlayerEventTypes.TIME_UPDATE, listener: timeUpdateListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] TimeUpdate listener dettached from THEOplayer") }
        }
        
        // PLAYING
        if let playingListener = self.playingListener {
            player.removeEventListener(type: PlayerEventTypes.PLAYING, listener: playingListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] Playing listener dettached from THEOplayer") }
        }
        
        // SEEKING
        if let seekingListener = self.seekingListener {
            player.removeEventListener(type: PlayerEventTypes.SEEKING, listener: seekingListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] Seeking listener dettached from THEOplayer") }
        }
        
        // SEEKED
        if let seekedListener = self.seekedListener {
            player.removeEventListener(type: PlayerEventTypes.SEEKED, listener: seekedListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] Seeked listener dettached from THEOplayer") }
        }
        
        // ENDED
        if let endedListener = self.endedListener {
            player.removeEventListener(type: PlayerEventTypes.ENDED, listener: endedListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] Ended listener dettached from THEOplayer") }
        }
        
        // ERROR
        if let errorListener = self.errorListener {
            player.removeEventListener(type: PlayerEventTypes.ERROR, listener: errorListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] Error listener dettached from THEOplayer") }
        }
        
        // LOADED_DATA
        if let loadedDataListener = self.loadedDataListener {
            player.removeEventListener(type: PlayerEventTypes.LOADED_DATA, listener: loadedDataListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] LoadedData listener dettached from THEOplayer") }
        }
        
        // LOADED_META_DATA
        if let loadedMetadataListener = self.loadedMetadataListener {
            player.removeEventListener(type: PlayerEventTypes.LOADED_META_DATA, listener: loadedMetadataListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] LoadedMetadata listener dettached from THEOplayer") }
        }
        
        // PRESENTATION_MODE_CHANGE
        if let presentationModeChangeListener = self.presentationModeChangeListener {
            player.removeEventListener(type: PlayerEventTypes.PRESENTATION_MODE_CHANGE, listener: presentationModeChangeListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] PresentationModeChange listener dettached from THEOplayer") }
        }
    }
    
    // MARK: - attach/dettach textTrackList Listeners
    private func attachTextTrackListListeners() {
        guard let player = self.player else {
            return
        }
        
        // ADD_TRACK
        self.addTrackListener = player.textTracks.addEventListener(type: TextTrackListEventTypes.ADD_TRACK) { [weak self] event in
            guard let welf = self else { return }
            if let forwardedTextTrackListEvent = welf.onNativeTextTrackListEvent,
               let textTrack = event.track as? TextTrack {
                if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received ADD_TRACK event from THEOplayer textTrack list: trackUid = \(textTrack.uid)") }
                // trigger tracklist event
                forwardedTextTrackListEvent([
                    "track" : THEOplayerRCTMetadataAggregator.aggregatedTextTrackInfo(textTrack: textTrack),
                    "type" : ADD_TRACK
                ])
                // start listening for cue events on this track and keep listener for later removal
                welf.addCueListeners[textTrack.uid] = textTrack.addEventListener(type: TextTrackEventTypes.ADD_CUE, listener: welf.addCueListener(_:))
                if DEBUG_EVENTHANDLER { print("[NATIVE] AddCue listener attached to THEOplayer textTrack with uid \(textTrack.uid)") }
                welf.removeCueListeners[textTrack.uid] = textTrack.addEventListener(type: TextTrackEventTypes.REMOVE_CUE, listener: welf.removeCueListener(_:))
                if DEBUG_EVENTHANDLER { print("[NATIVE] RemoveCue listener attached to THEOplayer textTrack with uid \(textTrack.uid)") }
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] AddTrack listener attached to THEOplayer textTrack list") }
        
        // REMOVE_TRACK
        self.removeTrackListener = player.textTracks.addEventListener(type: TextTrackListEventTypes.REMOVE_TRACK) { [weak self] event in
            guard let welf = self else { return }
            if let forwardedTextTrackListEvent = welf.onNativeTextTrackListEvent,
               let textTrack = event.track as? TextTrack {
                if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received REMOVE_TRACK event from THEOplayer textTrack list: trackUid = \(textTrack.uid)") }
                // trigger tracklist event
                forwardedTextTrackListEvent([
                    "track" : THEOplayerRCTMetadataAggregator.aggregatedTextTrackInfo(textTrack: textTrack),
                    "type" : REMOVE_TRACK
                ])
                // stop listening for cue events on this track
                if let addCueListener = welf.addCueListeners[textTrack.uid],
                   let removeCueListener = welf.removeCueListeners[textTrack.uid]{
                    textTrack.removeEventListener(type: TextTrackEventTypes.ADD_CUE, listener: addCueListener)
                    if DEBUG_EVENTHANDLER { print("[NATIVE] AddCue listener removed from THEOplayer textTrack with uid \(textTrack.uid)") }
                    textTrack.removeEventListener(type: TextTrackEventTypes.REMOVE_CUE, listener: removeCueListener)
                    if DEBUG_EVENTHANDLER { print("[NATIVE] RemoveCue listener removed from THEOplayer textTrack with uid \(textTrack.uid)") }
                }
            }
        }
        if DEBUG_EVENTHANDLER { print("[NATIVE] RemoveTrack listener attached to THEOplayer textTrack list") }
    }
    
    private func dettachTextTrackListListeners() {
        guard let player = self.player else {
            return
        }
        
        // ADD_TRACK
        if let addTrackListener = self.addTrackListener {
            player.textTracks.removeEventListener(type: TextTrackListEventTypes.ADD_TRACK, listener: addTrackListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] AddTrack listener dettached from THEOplayer textTrack list") }
        }
        
        // REMOVE_TRACK
        if let removeTrackListener = self.removeTrackListener {
            player.textTracks.removeEventListener(type: TextTrackListEventTypes.REMOVE_TRACK, listener: removeTrackListener)
            if DEBUG_EVENTHANDLER { print("[NATIVE] RemoveTrack listener dettached from THEOplayer textTrack list") }
        }
    }
    
    // MARK: - dynamic textTrack Listeners
    private func addCueListener(_ event: AddCueEvent) {
        if let forwardedTextTrackEvent = self.onNativeTextTrackEvent,
           let textTrack = event.cue.track {
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received ADD_CUE event from textTrack: trackUid = \(textTrack.uid), cueUid = \(event.cue.uid)") }
            forwardedTextTrackEvent([
                "trackUid" : textTrack.uid,
                "type": ADD_CUE,
                "cue": THEOplayerRCTMetadataAggregator.aggregatedTextTrackCueInfo(textTrackCue: event.cue)
            ])
        }
    }
    
    private func removeCueListener(_ event: RemoveCueEvent) {
        if let forwardedTextTrackEvent = self.onNativeTextTrackEvent,
           let textTrack = event.cue.track {
            if DEBUG_THEOPLAYER_EVENTS { print("[NATIVE] Received REMOVE_CUE event from textTrack: trackUid = \(textTrack.uid), cueUid = \(event.cue.uid)") }
            forwardedTextTrackEvent([
                "trackUid" : textTrack.uid,
                "type": REMOVE_CUE,
                "cue": THEOplayerRCTMetadataAggregator.aggregatedTextTrackCueInfo(textTrackCue: event.cue)
            ])
        }
    }
}
