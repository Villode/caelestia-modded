pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQml

Singleton {
    id: root

    readonly property string currentLine: _currentLine
    readonly property bool available: _lines.length > 0
    readonly property real currentLineDuration: _currentLineDuration
    property string _currentLine: ""
    property real _currentLineDuration: 0
    property var _lines: []
    property string _lastTrackId: ""

    function parseLrc(lrc: string): var {
        const lines = [];
        const regex = /\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)/;
        for (const line of lrc.split("\n")) {
            const match = line.match(regex);
            if (match) {
                const min = parseInt(match[1]);
                const sec = parseInt(match[2]);
                let ms = parseInt(match[3]);
                if (match[3].length === 2) ms *= 10;
                const time = min * 60 + sec + ms / 1000;
                const text = match[4].trim();
                if (text.length > 0)
                    lines.push({ time, text });
            }
        }
        lines.sort((a, b) => a.time - b.time);
        return lines;
    }

    function updateCurrentLine(positionSec: real): void {
        if (_lines.length === 0) {
            _currentLine = "";
            _currentLineDuration = 0;
            return;
        }
        let idx = 0;
        for (let i = _lines.length - 1; i >= 0; i--) {
            if (positionSec >= _lines[i].time) {
                idx = i;
                break;
            }
        }
        _currentLine = _lines[idx].text;
        _currentLineDuration = idx < _lines.length - 1
            ? _lines[idx + 1].time - _lines[idx].time
            : 5;
    }

    function fetchForTrack(trackUrl: string): void {
        const match = trackUrl.match(/\/trackid\/(\d+)/);
        if (!match) {
            _lines = [];
            _currentLine = "";
            _lastTrackId = "";
            return;
        }
        const trackId = match[1];
        if (trackId === _lastTrackId && _lines.length > 0)
            return;
        _lastTrackId = trackId;
        _lines = [];
        _currentLine = "";
        fetcher.command = ["python3", `${Quickshell.shellDir}/assets/lyrics_fetcher.py`, trackId];
        fetcher.running = true;
    }

    Process {
        id: fetcher

        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output.length > 0) {
                    root._lines = root.parseLrc(output);
                }
            }
        }
    }
}
