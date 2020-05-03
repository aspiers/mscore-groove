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

        var track_rand_factories = {
            0: smoothed_random_factory(5),
            4: smoothed_random_factory(5),
            8: smoothed_random_factory(5),
            12: smoothed_random_factory(5)
        };

        //process_bars();
        walk(track_rand_factories);
        // test_groove();

        curScore.endCmd();

        Qt.quit()
    }

    function test_groove() {
        var Groove = groove_factory;

        var groove = new Groove(
            fraction(7, 8),
            [1, 1, 1, 1, 1, 1, 1],
            [2, 1, 1, 2, 2, 1, 2],
            80 // percentage
        );

        Array.prototype.groove = function (groove) {
            return this.map(function (x) { return groove.map(x); });
        };

        ilog(1, [0, 120, 240, 1000].groove(groove));
    }

    function groove_factory(cycle_len, a_ratios, b_ratios, percent) {
        var groove = {
            a_ratios: a_ratios,
            b_ratios: b_ratios,
            percent: percent || 50,
            a_ticks: ratio_to_ticks(cycle_len, a_ratios),
            b_ticks: ratio_to_ticks(cycle_len, b_ratios),

            map: function (a) {
                if (this.a_ticks.length != this.b_ticks.length) {
                    console.exception(
                        "ticks length mismatch:",
                        this.a_ticks.length, "vs.", this.b_ticks.length
                    );
                    return null;
                }

                if (a < this.a_ticks[0]) {
                    console.exception("Tick", a, "is below input range");
                    return null;
                }
                if (a > this.a_ticks[this.a_ticks.length - 1]) {
                    console.exception("Tick", a, "is above input range");
                    return null;
                }

                for (var i = 0; i < this.a_ticks.length - 1; i++) {
                    // ilog(2,
                    //      "a interval from", this.a_ticks[i],
                    //      "to", this.a_ticks[i + 1]);
                    if (this.a_ticks[i] <= a && a <= this.a_ticks[i + 1]) {
                        var a_interval = this.a_ticks[i + 1] - this.a_ticks[i];
                        var b_interval = this.b_ticks[i + 1] - this.b_ticks[i];
                        var a_delta = (a - this.a_ticks[i]) / a_interval;
                        var b = this.b_ticks[i] + a_delta * b_interval;
                        return ((100 - this.percent) * a + this.percent * b) / 100;
                    }
                }
            }
        };
        return groove;
    }

    function ratio_to_ticks(cycle_len, ratios) {
        var cumulative = cumsum(ratios);
        var total = cumulative[cumulative.length - 1];
        return cumulative.map(function (x) {
            return x / total * cycle_len.ticks;
        });
    }

    function cumsum(nums) {
        var t = 0;
        var cumulative = [t];
        for (var i = 0; i < nums.length; i++) {
            t += nums[i];
            cumulative.push(t);
        }
        return cumulative;
    }

    function die() {
        console.error.apply(this, arguments);
        Qt.quit();
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

    function walk(trfs) {
        var i = 1;

        var cursor = curScore.newCursor();
        cursor.rewind(Cursor.SCORE_START);
        // cursor.rewind(Cursor.SELECTION_START);
        ilog(0, "cursor.element " + cursor.element.name);
        for (var seg = cursor.segment; seg; seg = cursor.nextMeasure()) {
            process_bar(trfs, i, cursor.measure);
            i++;
        }
    }

    function process_bar(trfs, i, bar) {
        // if (i != 3) return;
        var seg = bar.firstSegment;
        var bar_start_tick = seg.tick;
        ilog(0, "Bar " + i + " starts at tick " + bar_start_tick);
        for (; seg; seg = seg.nextInMeasure) {
            process_segment(trfs, i, bar_start_tick, seg);
        }
    }

    function process_segment(trfs, bar, bar_start_tick, seg) {
        var bar_tick = seg.tick - bar_start_tick;

        // top voice of top (lead) part
        process_segment_track(trfs, 0, bar, bar_tick, seg, 200, 250, 100,
                              [60, 75, 60, 75, 60, 75, 60, 75]);

        // top voice of second (bass) part
        process_segment_track(trfs, 4, bar, bar_tick, seg, 200, -50, 100,
                              [70, 100, 85, 100, 60, 100, 85, 100]);

        // top voice of third (drums) part
        process_segment_track(trfs, 8, bar, bar_tick, seg, 350, 0, 100,
                              [80, 60, 110, 70, 80, 60, 110, 70]);

        // lower voice of third (drums) part
        process_segment_track(trfs, 12, bar, bar_tick, seg, 300, 0, 100,
                              [100, 100, 60, 60, 100, 100, 60, 60]);
    }

    function process_segment_track(trfs, track, bar, bar_tick, seg, swing,
                                   lay_back_delta, random, envelope) {
        var el = seg.elementAt(track);
        if (el) {
            if (el.type == Element.CHORD) {
                show_seg(track, bar, bar_tick, seg);
                // show_timing(2, seg);
                ilog(
                    2, el.name,
                    "dur", el.duration.str, el.duration.ticks
                );
                var notes = el.notes;
                for (var i = 0; i < notes.length; i++) {
                    if (true) {
                        process_note(trfs[track], track, bar, bar_tick, notes[i],
                                     swing, lay_back_delta, random, envelope);
                    } else {
                        reset_to_straight(notes[i]);
                    }
                }
            } else {
                // show_seg(track, bar, bar_tick, seg);
                // ilog(2, "tick", bar_tick + ": not a chord:", el.name);
            }
        }
    }

    function show_seg(track, bar, bar_tick, seg) {
        var quaver = bar_tick / 240;
        ilog(
            1, "track", track,
            "bar", bar,
            seg.name,
            "quaver", quaver,
            "dur", seg.duration.str, seg.duration.ticks
        );
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

    function process_note(trf, track, bar, bar_tick, note,
                          swing, lay_back_delta, random, envelope) {
        var pevts = note.playEvents;
        var ontime_quaver = bar_tick / 240;
        ilog(
            3, note.name,
            "@ quaver", ontime_quaver,
            "pitch", note.pitch,
            "veloc", note.veloOffset,
            "playEvents", pevts.length
        );

        var actual_tick_len = get_element_tick_len(note.parent);
        // show_timing(4, note);

        var pevt = pevts[0];
        pevt.ontime = 0;
        pevt.len = 1000;

        if (actual_tick_len % 240 == 0 &&
            ontime_quaver == Math.round(ontime_quaver)) {
            swing_note(ontime_quaver, note, swing, envelope);
            adjust_velocity(ontime_quaver, note, envelope);
        } else {
            ilog(4,
                 "not a quaver multiple;",
                 "bar tick", bar_tick,
                 "notated len", note.playEvents[0].len);
        }

        lay_back_note(ontime_quaver, note, lay_back_delta);
        randomise_placement(trf, note, random);
        var pevt = pevts[0];
        ilog(
            4, "now:",
            "veloc", note.veloOffset,
            "on", pevt.ontime,
            "len", pevt.len,
            "off", pevt.offtime
        );
    }

    function get_element_tick_len(el) {
        // FIXME: The API doesn't yet provide any way to figure out
        // whether a note is part of a tuplet, so we have to find the
        // delta to the tick of the next segment to figure out the real
        // length of the note.  The API shouldn't make us do this.
        var seg = el.parent;
        var next_chord_rest = find_adjacent_chord_rest(el.track, seg, 1);
        var actual_tick_len = el.duration.ticks;
        if (next_chord_rest) {
            var next_seg = next_chord_rest.parent;
            actual_tick_len = next_seg.tick - seg.tick;
            ilog(
                4,
                "len", actual_tick_len, "ticks:",
                "seg.tick", seg.tick,
                "next_seg.tick", next_seg.tick
            );
        }
        else {
            ilog(
                4,
                "len", actual_tick_len, "ticks"
            );
        }
        return actual_tick_len;
    }

    function get_note_off_tick(note) {
        var chord = note.parent;
        var seg = chord.parent;
        var tick_len = get_element_tick_len(chord);
        return seg.tick + tick_len;
    }

    function reset_to_straight(note) {
        note.veloType = NoteValueType.OFFSET_VAL;
        note.veloOffset = 0;
        var pevt = note.playEvents[0];
        pevt.ontime = 0;
        pevt.len = 1000;
    }

    function adjust_velocity(quaver, note, envelope) {
        note.veloType = NoteValueType.USER_VAL;
        // ilog(4, envelope, quaver);
        note.veloOffset = envelope[quaver];
        var prev_note = find_adjacent_note(note, -1);
        var next_note = find_adjacent_note(note,  1);
        if (prev_note && prev_note.pitch < note.pitch &&
            (!next_note || (next_note.pitch < note.pitch))) {
            ilog(4, "> accenting peak of phrase");
            // FIXME: adjust relative to contour?
            note.veloOffset = 115;
            if (legato_notes(prev_note, note)) {
                // Articulate notes immediately before accented peaks
                ilog(4, ". shortening note immediately before peak");
                prev_note.playEvents[0].len -= 300;
            }
        } else if (next_note) {
            var now = note.parent.parent.tick;
            var next = next_note.parent.parent.tick;
            ilog(4, "now", now, "next", next, "delta", next - now);
            if (next - now > 240) {
                ilog(4, "> accenting end of phrase");
                note.veloOffset = 90;
            }
        }
    }

    function legato_notes(note_a, note_b) {
        // ilog(5, "legato_notes?")
        var note_a_off_tick = get_note_off_tick(note_a);
        var seg_b = note_b.parent.parent;
        // ilog(5, "note_a_off_tick", note_a_off_tick,
        //      "seg_b.tick", seg_b.tick);
        return note_a_off_tick == seg_b.tick;
    }

    function cursor_at_tick(track, tick) {
        var cursor = curScore.newCursor();
        cursor.staffIdx = track / 4;
        cursor.voice    = track % 4;
        cursor.rewind(Cursor.SCORE_START);
        // FIXME: this is horribly inefficient
        while (cursor.segment.tick != tick) {
            cursor.next();
        }
        // ilog(5, "cursor_at_tick", cursor.segment.tick, tick);
        return cursor;
    }

    function find_adjacent_note(note, direction) {
        var seg = note.parent.parent;
        var el = find_adjacent_chord_rest(note.track, seg, direction,
                                          Element.CHORD);
        if (el === null) {
            return el;
        }
        return get_highest_note_in_chord(el);
    }

    function find_adjacent_chord_rest(track, seg, direction, type) {
        var cursor = cursor_at_tick(track, seg.tick);
        // ilog(5, "find_adjacent_chord_rest START seg tick", seg.tick, cursor);
        var el;
        var type_matched = false;
        while (true) {
            if (direction > 0) {
                cursor.next();
            } else {
                cursor.prev();
            }
            // ilog(5, "find_adjacent_chord_rest segment", cursor.segment);
            if (! cursor.segment) {
                // ilog(5, "find_adjacent_chord_rest ran out of segments");
                return null;
            }
            el = cursor.segment.elementAt(track);
            // ilog(5, "find_adjacent_chord_rest seg tick", seg.tick, "el", el);

            if (! el) {
                // Cursor should be filtering for (Ms::SegmentType::ChordRest)
                // elements within the current track, so presumably every
                // segment should have an element.
                ilog(1,
                     "!!!!! BUG? find_adjacent_chord_rest got null element",
                     "at seg tick", seg.tick);
                continue;  // Keep looking
            }

            if (! type) {
                // Chord or rest
                return el;
            } else if (el.type == type) {
                // Got the type asked for
                return el;
            }
        }
    }

    function get_highest_note_in_chord(chord) {
        var notes = chord.notes;
        var highest = notes[0];
        for (var i = 1; i < notes.length; i++) {
            if (notes[i].pitch > highest.pitch) {
                highest = notes[i];
            }
        }
        // ilog(5, "adj note", highest.pitch);
        return highest;
    }

    function swing_note(quaver, note, swing, lay_back_delta) {
        var swing_delta = swing;
        var pevt = note.playEvents[0];
        var orig_duration = note.parent.duration.ticks;
        swing_delta *= 240 / orig_duration;
        // var pevt = note.createPlayEvent();
        if (quaver % 2 == 0) {
            // On-beat
            pevt.ontime = 0;
            pevt.len = 1000 + swing_delta;
            // ilog(4, "swing: lengthened");
        } else {
            // Off-beat
            pevt.ontime = swing_delta;
            pevt.len = 1000 - swing_delta;
            // ilog(4, "swing: delayed / shortened");
        }
    }

    function lay_back_note(quaver, note, lay_back_delta) {
        var pevt = note.playEvents[0];
        pevt.ontime += lay_back_delta;
    }

    function randomise_placement(trf, note, plus_minus_max) {
        var pevt = note.playEvents[0];
        var orig = pevt.ontime;
        pevt.ontime += (trf.get() - 0.5) * 2 * plus_minus_max;
        ilog(4, "ontime", orig, "-> random", pevt.ontime);
    }

    function smoothed_random_factory(moving_avg_len) {
        var factory = {
            randoms: [],
            get: function () {
                var r = Math.random();
                this.randoms.push(r);
                if (this.randoms.length > moving_avg_len) {
                    this.randoms.shift();
                }
                var sum = 0;
                for (var i=0; i < this.randoms.length; i++) {
                    sum += this.randoms[i];
                }
                var moving_avg = sum / moving_avg_len;
                return moving_avg;
            }
        };
        for (var i=0; i < 15; i++) {
            factory.get();
        }
        return factory;
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
