import QtQuick 2.0
import MuseScore 3.0

MuseScore {
    menuPath: "Plugins.Groove"
    description: "Groove harder"
    version: "1.0"
    onRun: {
        polyfills();

        curScore.startCmd();

        console.log("Score has " + curScore.nstaves + " staves");
        show_parts();
        console.log("Selection: " + curScore.selection);

        //process_bars();
        walk();

        curScore.endCmd();

        Qt.quit()
    }

    function show_parts() {
        console.log("Parts:");
        for (var i = 0; i < curScore.parts.length; i++) {
            var part = curScore.parts[i];
            ilog(
                1, part.longName + ": ",
                "start track", part.startTrack,
                "end track", part.endTrack
            );
        }
    }

    function process_selection() {
        //var selection = curScore.selection;
        //var elements = selection.elements;
        //for (var i = 0; i < elements.length; i++) {
    }

    function process_bars() {
        var i = 1;
        for (var bar = curScore.firstMeasure; bar; bar = bar.nextMeasure) {
            process_bar(i, bar);
            i++;
        }
    }

    function walk() {
        var i = 1;
        var cursor = curScore.newCursor();
        cursor.rewind(Cursor.SCORE_START);
        // cursor.rewind(Cursor.SELECTION_START);
        ilog(0, "cursor.element " + cursor.element.name);
        for (var seg = cursor.segment; seg; seg = cursor.nextMeasure()) {
            process_bar(i, cursor.measure);
            i++;
        }
    }

    function process_bar(i, bar) {
        var seg = bar.firstSegment;
        var bar_start_tick = seg.tick;
        ilog(0, "Bar " + i + " starts at tick " + bar_start_tick);
        for (; seg; seg = seg.nextInMeasure) {
            process_segment(bar_start_tick, seg);
        }
    }

    function process_segment(bar_start_tick, seg) {
        var bar_tick = seg.tick - bar_start_tick;

        // top voice of top (lead) part
        process_segment_track(bar_tick, seg, 0, 300,
                              [60, 100, 60, 100, 60, 100, 60, 100]);

        // top voice of second (bass) part
        process_segment_track(bar_tick, seg, 4, 0,
                              [60, 120, 100, 120, 60, 120, 100, 120]);
    }

    function process_segment_track(bar_tick, seg, track, lay_back_delta,
                                   envelope) {
        var quaver = bar_tick / 240;
        ilog(
            1, "track", track,
            seg.name,
            "quaver", quaver,
            "dur", seg.duration.str, seg.duration.ticks,
            "par", seg.parent.type
        );
        // show_timing(2, seg);

        var el = seg.elementAt(track);
        if (el) {
            if (el.type == Element.CHORD) {
                ilog(
                    2, el.name,
                    "dur", el.duration.str, el.duration.ticks,
                    "par", el.parent.type
                );
                var notes = el.notes;
                for (var i = 0; i < notes.length; i++) {
                    process_note(track, bar_tick, notes[i], lay_back_delta, envelope);
                }
            } else {
                ilog(2, "tick", bar_tick + ": not a chord:", el.name);
            }
        }
    }

    function show_timing(indent, el) {
        for (var prop in el) {
            //if (prop.match("[dD]uration|[tT]ime|atorString")) {
            if (prop.match("durationType")) {
                var val = el[prop];
                if (val) {
                    if (val.str) {
                        val = "FractionWrapper " + val.str;
                    } else if (val.ticks) {
                        val = val + " " + val.ticks + " ticks";
                    }
                }
                ilog(indent, el.name, prop, val);
            }
        }
    }

    function process_note(track, bar_tick, note, lay_back_delta, envelope) {
        var quaver = bar_tick / 240;
        var orig_len = note.parent.duration.ticks;
        var pevts = note.playEvents;
        ilog(
            3, note.name,
            "par", note.parent.type,
            "par2", note.parent.parent.type,
            "len", orig_len / 240,
            "pitch", note.pitch,
            "veloc", note.veloOffset,
            "playEvents", pevts.length
        );
        // show_timing(4, note);

        if (orig_len % 240 == 0 &&
            quaver == Math.round(quaver)) {
            adjust_velocity(quaver, note, envelope);
        } else {
            ilog(3, "duration not a quaver multiple",
                 quaver, bar_tick, note.playEvents[0].len);
        }

        swing_note(quaver, note, envelope);
        lay_back_note(quaver, note, lay_back_delta);
        var pevt = note.playEvents[0];
        pevt.ontime = 0
        pevt.len = 1000;
        log(
            4, "now:",
            "veloc", note.veloOffset,
            "on", pevt.ontime,
            "off", pevt.offtime
        );
    }

    function adjust_velocity(quaver, note, envelope) {
        // note.veloType = NoteValueType.OFFSET_VAL;
        note.veloType = NoteValueType.USER_VAL;
        // ilog(4, envelope, quaver);
        note.veloOffset = envelope[quaver];
        if (note.track == 0) { // REMOVE
            var prevNote = find_adjacent_note(note, -1);
            var nextNote = find_adjacent_note(note,  1);
            if (prevNote && prevNote.pitch < note.pitch &&
                nextNote && nextNote.pitch < note.pitch) {
                ilog(4, "> accenting peak of phrase");
                // FIXME: adjust relative to contour?
                note.veloOffset += 20;
            }
        }
    }

    function find_adjacent_note(note, direction) {
        var seg = note.parent.parent;
        var el;
        // ilog(5, "find_adjacent_note START seg tick", seg.tick);
        do {
            seg = direction > 0 ? seg.next : seg.prev;
            if (! seg) {
                ilog(5, "find_adjacent_note ran out of segments");
                return null;
            }
            el = seg.elementAt(note.track);
            // ilog(5, "find_adjacent_note seg tick", seg.tick, "el", el);
        }
        while (! (el && el.type == Element.CHORD));

        var notes = el.notes;
        var highest = notes[0];
        for (var i = 1; i < notes.length; i++) {
            if (notes[i].pitch > highest.pitch) {
                highest = notes[i];
            }
        }
        // ilog(5, "adj note", highest.pitch);
        return highest;
    }

    function swing_note(quaver, note, lay_back_delta) {
        var swing_delta = 200;
        var pevt = note.playEvents[0];
        var orig_duration = note.parent.duration.ticks;
        swing_delta *= 240 / orig_duration;
        // var pevt = note.createPlayEvent();
        if (quaver % 2 == 0) {
            // On-beat
            pevt.ontime = 0;
            pevt.len = 1000 + swing_delta;
        } else {
            // Off-beat
            pevt.ontime = swing_delta;
            pevt.len = 1000 - swing_delta;
        }
    }

    function lay_back_note(quaver, note, lay_back_delta) {
        var pevt = note.playEvents[0];
        pevt.ontime += lay_back_delta;
    }

    function dump_play_ev(event) {
        ilog(0, "on time", event.ontime, "len", event.len, "off time", event.ontime+event.len);
    }

    function ilog() {
        // Stupid ES5.  Voodoo from StackOverflow: steal Array.splice and
        // apply it to the Arguments object:
        // https://stackoverflow.com/questions/11327657/remove-and-add-elements-to-functions-argument-list-in-javascript/21804297#21804297
        var indent_level = [].splice.call(arguments, 0, 1);
        var indent = " ".repeat(5 * indent_level);
        [].splice.call(arguments, 0, 0, indent);
        console.log.apply(this, arguments);
    }

    function polyfills() {
        // More stupid ES5.
        polyfill_string_repeat();
    }

    function polyfill_string_repeat() {
        if (!String.prototype.repeat) {
            String.prototype.repeat = function(count) {
                'use strict';
                if (this == null)
                    throw new TypeError('can\'t convert ' + this + ' to object');

                var str = '' + this;
                // To convert string to integer.
                count = +count;
                // Check NaN
                if (count != count)
                    count = 0;

                if (count < 0)
                    throw new RangeError('repeat count must be non-negative');

                if (count == Infinity)
                    throw new RangeError('repeat count must be less than infinity');

                count = Math.floor(count);
                if (str.length == 0 || count == 0)
                    return '';

                // Ensuring count is a 31-bit integer allows us to heavily optimize the
                // main part. But anyway, most current (August 2014) browsers can't handle
                // strings 1 << 28 chars or longer, so:
                if (str.length * count >= 1 << 28)
                    throw new RangeError('repeat count must not overflow maximum string size');

                var maxCount = str.length * count;
                count = Math.floor(Math.log(count) / Math.log(2));
                while (count) {
                    str += str;
                    count--;
                }
                str += str.substring(0, maxCount - str.length);
                return str;
            }
        }
    }
}
