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

        var Groove = groove_factory;

        var groove_palette = {
            straight: new Groove(
                fraction(1, 4),
                [1, 1],
                [1, 1],
                {
                    swing_percentage: 0,
                    velocity_envelope: [-1, -1],
                }
            ),
            viennese_waltz: new Groove(
                fraction(3, 4),
                [1, 1, 1],
                [1, 3, 2],
                {
                    swing_percentage: 30,
                }
            ),
            bop_lead: new Groove(
                fraction(8, 8),
                [1, 1, 1, 1, 1, 1, 1, 1],
                [2, 1, 2, 1, 2, 1, 2, 1],
                {
                    swing_percentage: 80,
                    lay_back_delta: 250,
                    velocity_envelope: [60, 75, 60, 75, 60, 75, 60, 75],
                    peak_velocity: 115,
                    pre_peak_shortening: 300,
                    phrase_end_velocity: 90
                }
            ),
            bop_bass: new Groove(
                fraction(8, 8),
                [1, 1, 1, 1, 1, 1, 1, 1],
                [2, 1, 2, 1, 2, 1, 2, 1],
                {
                    swing_percentage: 70,
                    lay_back_delta: -50,
                    velocity_envelope: [70, 100, 85, 100, 60, 100, 85, 100],
                }
            ),
            bop_drums_1: new Groove(
                fraction(8, 8),
                [1, 1, 1, 1, 1, 1, 1, 1],
                [2, 1, 2, 1, 2, 1, 2, 1],
                {
                    swing_percentage: 120,
                    velocity_envelope: [80, 60, 110, 70, 80, 60, 110, 70],
                }
            ),
            bop_drums_2: new Groove(
                fraction(8, 8),
                [1, 1, 1, 1, 1, 1, 1, 1],
                [2, 1, 2, 1, 2, 1, 2, 1],
                {
                    swing_percentage: 120,
                    velocity_envelope: [100, 100, 60, 60, 100, 100, 60, 60],
                }
            ),
            samba: new Groove(
                fraction(8, 8),
                [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
                [3, 2, 2, 3, 3, 2, 2, 3, 3, 2, 2, 3, 3, 2, 2, 3],
                {
                    swing_percentage: 80,
                    velocity_envelope: [
                        100, 100, 40, 110, 90, 100, 40, 110,
                        90, 100, 40, 110, 90, 100, 40, 110
                    ],
                }
            ),
            braff_piano: new Groove(
                fraction(7, 8),
                [1, 1, 1, 1, 1, 1, 1],
                [3, 1, 2, 3, 3, 2, 3],
                {
                    swing_percentage: 70,
                    velocity_envelope: [80, 50, 60, 80, 80, 60, 80],
                    articulation_envelope: [500, 500, 500, 500, 500, 500, 500],
                    peak_velocity: 100
                }
            ),
            braff_bass: new Groove(
                fraction(7, 8),
                [1, 1, 1, 1, 1, 1, 1],
                [3, 1, 2, 3, 3, 2, 3],
                {
                    swing_percentage: 70,
                    velocity_envelope: [80, 50, 60, 80, 80, 60, 80],
                    articulation_envelope: [300, 300, 300, 300, 300, 300, 300],
                    peak_velocity: 100
                }
            )
        };

        var straight_tracks = get_track_context({
            0:  [0, groove_palette.straight],
            4:  [0, groove_palette.straight],
            8:  [0, groove_palette.straight],
            12: [0, groove_palette.straight]
        });

        var scrapple_tracks = get_track_context({
            0:  [100, groove_palette.bop_lead],
            4:  [100, groove_palette.bop_bass],
            8:  [100, groove_palette.bop_drums_1],
            12: [100, groove_palette.bop_drums_2]
        });

        var braff_tracks = get_track_context({
            0:  [200, groove_palette.braff_piano],
            4:  [100, groove_palette.braff_bass],
        });

        var samba_tracks = get_track_context({
            0:  [100, groove_palette.samba],
            4:  [100, groove_palette.samba],
            8:  [100, groove_palette.samba],
            12: [100, groove_palette.samba],
            16: [100, groove_palette.samba],
            20: [100, groove_palette.samba]
        });

        // test_groove();
        // process_bars();

        // groove_palette.bop_lead.swing_percentage = 0;
        walk_score(scrapple_tracks);

        curScore.endCmd();

        Qt.quit()
    }

    function get_track_context(tracks) {
        var TrackContext = track_context;

        for (var i in tracks) {
            var randomness = tracks[i][0];
            var groove = tracks[i][1];
            tracks[i] = new TrackContext(i, randomness, groove);
        }

        return tracks;
    }

    function test_groove() {
        var Groove = groove_factory;

        var groove = new Groove(
            fraction(7, 8),
            [1, 1, 1, 1, 1, 1, 1],
            [2, 1, 1, 2, 2, 1, 2],
            { swing_percentage: 80 }
        );

        Array.prototype.groove = function (groove) {
            return this.map(function (x) { return groove.map_tick(x); });
        };

        ilog(1, [0, 120, 240, 1000].groove(groove));
    }

    function track_context(track_num, randomness, groove) {
        var context = {
            num: track_num,
            groove: groove,
            randomness: randomness,
            rng: smoothed_random_factory(5),

            random: function () {
                return (this.rng.get() - 0.5) * 2 * this.randomness;
            }
        };
        return context;
    }

    function groove_factory(cycle_len, a_ratios, b_ratios, options) {
        if (a_ratios.length != b_ratios.length) {
            console.exception(
                "ratios length mismatch:",
                a_ratios.length, "vs.", b_ratios.length
            );
            return null;
        }

        var groove = {
            a_ratios: a_ratios,
            b_ratios: b_ratios,
            a_ticks: ratio_to_ticks(cycle_len, a_ratios),
            b_ticks: ratio_to_ticks(cycle_len, b_ratios),
            swing_percentage: options.swing_percentage == null ?
                50 : options.swing_percentage,
            lay_back_delta: options.lay_back_delta || 0,
            velocity_envelope: options.velocity_envelope,
            articulation_envelope: options.articulation_envelope,
            peak_velocity: options.peak_velocity,
            pre_peak_shortening: options.pre_peak_shortening,
            phrase_end_velocity: options.phrase_end_velocity,

            has_source_tick: function (tick) {
                // No Array.includes in ES5?
                for (var i = 0; i < this.a_ticks.length; i++) {
                    if (tick == this.a_ticks[i]) {
                        return true;
                    }
                }
                return false;
            },

            map_tick: function (a) {
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
                        // ilog(2,
                        //      (100 - this.swing_percentage) + "%", a,
                        //      "+", this.swing_percentage + "%", b,
                        //      "/ 100");
                        return (
                            (100 - this.swing_percentage) * a
                                + this.swing_percentage * b)
                            / 100;
                    }
                }
            },

            tick_velocity: function (tick) {
                for (var i = 0; i < this.a_ticks.length; i++) {
                    if (tick == this.a_ticks[i]) {
                        return this.velocity_envelope[i];
                    }
                }
                // console.exception(
                //     "No velocity defined for tick", tick,
                //     "in groove with ticks", this.a_ticks
                // );
            },

            tick_articulation: function (tick) {
                for (var i = 0; i < this.a_ticks.length; i++) {
                    if (tick == this.a_ticks[i]) {
                        return this.articulation_envelope[i];
                    }
                }
                // console.exception(
                //     "No articulation length defined for tick", tick,
                //     "in groove with ticks", this.a_ticks
                // );
            },

            clone: function () {
                return Object.create(this);
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
        var selection = curScore.selection;
        var elements = selection.elements;
        for (var i = 0; i < elements.length; i++) {
        }
    }

    function process_bars() {
        var i = 1;
        for (var bar = curScore.firstMeasure; bar; bar = bar.nextMeasure) {
            process_bar(i, bar);
            i++;
        }
    }

    function walk_score(tracks) {
        var i = 1;

        var cursor = curScore.newCursor();
        cursor.rewind(Cursor.SCORE_START);
        // cursor.rewind(Cursor.SELECTION_START);
        ilog(0, "cursor.element " + cursor.element.name);
        for (var seg = cursor.segment; seg; seg = cursor.nextMeasure()) {
            process_bar(tracks, i, cursor.measure);
            i++;
        }
    }

    function process_bar(tracks, i, bar) {
        // if (i > 1) return;
        var seg = bar.firstSegment;
        var bar_start_tick = seg.tick;
        ilog(0, "Bar " + i + " starts at tick " + bar_start_tick);
        for (; seg; seg = seg.nextInMeasure) {
            process_segment(tracks, i, bar_start_tick, seg);
        }
    }

    function process_segment(tracks, bar, bar_start_tick, seg) {
        var bar_tick = seg.tick - bar_start_tick;

        for (var i in tracks) {
            var track = tracks[i];
            process_track_segment(track, bar, bar_tick, seg);
        }
    }

    function process_track_segment(track, bar, bar_tick, seg) {
        var el = seg.elementAt(track.num);
        if (! el) {
            return;
        }

        if (el.type == Element.CHORD) {
            process_chord(track, bar, bar_tick, seg, el);
        } else {
            // show_seg(track, bar, bar_tick, seg);
            // ilog(2, "tick", bar_tick + ": not a chord:", el.name);
        }
    }

    function process_chord(track, bar, bar_tick, seg, el) {
        show_seg(track, bar, bar_tick, seg);
        // show_timing(2, seg);
        ilog(
            2, el.name,
            "dur", el.duration.str, el.duration.ticks
        );
        var notes = el.notes;
        for (var i = 0; i < notes.length; i++) {
            if (true) {
                process_note(track, bar, bar_tick, notes[i]);
            } else {
                reset_to_straight(notes[i]);
            }
        }
    }

    function show_seg(track, bar, bar_tick, seg) {
        var quaver = bar_tick / 240;
        ilog(
            1, "track", track.num,
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

    function process_note(track, bar, bar_on_tick, note) {
        var pevts = note.playEvents;
        ilog(
            3, note.name,
            "@ quaver", bar_on_tick / 240,
            "pitch", note.pitch,
            "veloc", note.veloOffset,
            "playEvents", pevts.length
        );

        // show_timing(4, note);

        var pevt = pevts[0];
        pevt.ontime = 0;
        pevt.len = 1000;

        maybe_swing_note(track, bar_on_tick, note);
        lay_back_note(track, note);
        randomise_placement(track, note);
        var pevt = pevts[0];
        ilog(
            4, "now:",
            "veloc", note.veloOffset,
            "on", pevt.ontime,
            "len", pevt.len,
            "off", pevt.offtime
        );
    }

    function maybe_swing_note(track, bar_on_tick, note) {
        var tick_len = get_note_tick_len(note);
        if (note_aligns_with_groove(track.groove, bar_on_tick, tick_len, note)) {
            swing_note(track, note, bar_on_tick, tick_len);
            adjust_velocity(track, note, bar_on_tick);
        }
    }

    function note_aligns_with_groove(groove, bar_on_tick, tick_len, note) {
        var bar_off_tick = bar_on_tick + tick_len;

        if (! groove.has_source_tick(bar_on_tick)) {
            ilog(4,
                 "bar on tick", bar_on_tick,
                 "not aligned with groove", groove.a_ticks + ";",
                 "notated len", note.playEvents[0].len);
            return false;
        }

        if (! groove.has_source_tick(bar_off_tick)) {
            ilog(4,
                 "bar off tick", bar_off_tick,
                 "not aligned with groove", groove.a_ticks + ";",
                 "notated len", note.playEvents[0].len);
            return false;
        }

        return true;
    }

    function get_chord_tick_len(chord) {
        // FIXME: The API doesn't yet provide any way to figure out
        // whether a note is part of a tuplet, so we have to find the
        // delta to the tick of the next segment to figure out the real
        // length of the note.  The API shouldn't make us do this.
        var seg = chord.parent;
        var next_chord_rest = find_adjacent_chord_rest(chord.track, seg, 1);
        var actual_tick_len = chord.duration.ticks;
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

    function get_note_tick_len(note) {
        return get_chord_tick_len(note.parent);
    }

    function get_note_on_tick(note) {
        var chord = note.parent;
        var seg = chord.parent;
        return seg.tick;
    }

    function get_note_off_tick(note) {
        return get_note_on_tick(note) + get_note_tick_len(note);
    }

    function reset_to_straight(note) {
        note.veloType = NoteValueType.OFFSET_VAL;
        note.veloOffset = 0;
        var pevt = note.playEvents[0];
        pevt.ontime = 0;
        pevt.len = 1000;
    }

    function adjust_velocity(track, note, bar_on_tick) {
        var quaver = bar_on_tick / 240;
        var new_velocity = track.groove.tick_velocity(bar_on_tick);
        if (new_velocity) {
            if (new_velocity >= 0) {
                note.veloType = NoteValueType.USER_VAL;
                // ilog(4, envelope, quaver);
                note.veloOffset = new_velocity;
            } else {
                note.veloType = NoteValueType.OFFSET_VAL;
                note.veloOffset = 0;
            }
        }
        maybe_accent_and_articulate(track.groove, note, bar_on_tick);
    }

    function maybe_accent_and_articulate(groove, note, bar_on_tick) {
        var prev_note = find_adjacent_note(note, -1);
        var next_note = find_adjacent_note(note,  1);

        if (groove.articulation_envelope) {
            note.playEvents[0].len -= groove.tick_articulation(bar_on_tick);
        }

        if (prev_note && prev_note.pitch < note.pitch &&
            (!next_note || (next_note.pitch < note.pitch))) {
            if (groove.peak_velocity) {
                ilog(4, "> accenting peak of phrase");
                // FIXME: adjust relative to contour?
                note.veloOffset = groove.peak_velocity;
            }
            if (groove.pre_peak_shortening && legato_notes(prev_note, note)) {
                // Articulate notes immediately before accented peaks
                ilog(4, ". shortening note immediately before peak");
                prev_note.playEvents[0].len -= groove.pre_peak_shortening;
            }
        } else if (next_note && groove.phrase_end_velocity) {
            var now = note.parent.parent.tick;
            var next = next_note.parent.parent.tick;
            // ilog(4, "now", now, "next", next, "delta", next - now);
            if (next - now > 240) {
                ilog(4, "> accenting end of phrase");
                note.veloOffset = groove.phrase_end_velocity;
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

    function swing_note(track, note, bar_on_tick, tick_len) {
        var bar_off_tick = bar_on_tick + tick_len;

        var pevt = note.playEvents[0];
        var new_on_tick = track.groove.map_tick(bar_on_tick);
        var new_off_tick = track.groove.map_tick(bar_off_tick);
        var new_tick_len = new_off_tick - new_on_tick;
        var new_ontime = (new_on_tick - bar_on_tick) / tick_len * 1000;
        ilog(4,
             "Changing on tick from", bar_on_tick, "to", new_on_tick,
             "actual tick_len", tick_len,
             "==", new_ontime, " / 1000");
        pevt.ontime = new_ontime;
        var new_len = new_tick_len / tick_len * 1000;
        ilog(4,
             "Changing off tick from", bar_off_tick, "to", new_off_tick,
             "new tick len", new_tick_len,
             "==", new_len, " / 1000");
        pevt.len = new_len;
    }

    function lay_back_note(track, note) {
        var pevt = note.playEvents[0];
        pevt.ontime += track.groove.lay_back_delta;
    }

    function randomise_placement(track, note) {
        var pevt = note.playEvents[0];
        var orig = pevt.ontime;
        pevt.ontime += track.random();
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
