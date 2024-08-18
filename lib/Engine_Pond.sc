// Based on the LiedMotor engine for norns by @willamthazard: 
// https://github.com/williamthazard/schicksalslied/blob/main/lib/LiedMotor_engine.lua

Engine_Pond : CroneEngine {
	
	var params;

	alloc {

SynthDef("sinfm",
	{ arg sinfm_carfreq = 440,
		sinfm_index = 1,
		sinfm_modnum = 1,
		sinfm_modeno = 1,
		sinfm_phase = 0,
		sinfm_attack = 0,
		sinfm_release = 0.4,
		sinfm_amp = 0.2,
		sinfm_pan = 0;

	var sinfm_modfreq = (sinfm_modnum/sinfm_modeno)*sinfm_carfreq;
	var sinfm_env = Env.perc(attackTime: sinfm_attack, releaseTime: sinfm_release, level: sinfm_amp).kr(doneAction: 2);
	var sinfm_signal = Pan2.ar((SinOsc.ar(sinfm_carfreq + (sinfm_index*sinfm_modfreq*SinOsc.ar(sinfm_modfreq)), sinfm_phase, sinfm_amp)*sinfm_env),sinfm_pan);

    Out.ar(
        0,
        sinfm_signal;
    )
}).add;

SynthDef("ringer",
	{ arg ringer_freq = 440,
		ringer_index = 3,
		ringer_amp = 0.2,
		ringer_pan = 0;

	var ringer_env = Env.perc(attackTime: 0.01, releaseTime: ringer_index*2, level: ringer_amp).kr(doneAction: 2);
	var ringer_signal = Pan2.ar((Ringz.ar(Impulse.ar(0), ringer_freq, ringer_index, ringer_amp)*ringer_env),ringer_pan);

    Out.ar(
        0,
        ringer_signal;
    )
}).add;

SynthDef("karplu",
	{ arg karplu_freq = 440,
		karplu_index = 3,
		karplu_coef = 0.5,
		karplu_amp = 0.2,
		karplu_pan = 0;

	var karplu_env = Env.perc(attackTime: 0.01, releaseTime: karplu_index*2, level: karplu_amp).kr(doneAction: 2);
	var karplu_signal = Pan2.ar((Pluck.ar(WhiteNoise.ar(0.1), Impulse.kr(0), karplu_freq.reciprocal, karplu_freq.reciprocal, karplu_index, karplu_coef)*karplu_env),karplu_pan);

    Out.ar(
        0,
        karplu_signal;
    )
}).add;

SynthDef("resonz",
	{ arg resonz_freq = 440,
		resonz_index = 0.1,
		resonz_amp = 4,
		resonz_pan = 0;

	var resonz_env = Env.perc(attackTime: 0.01, releaseTime: resonz_index*30, level: resonz_amp).kr(doneAction: 2);
	var resonz_signal = Pan2.ar((Resonz.ar(Impulse.ar(0), resonz_freq, resonz_index, resonz_amp)*resonz_env),resonz_pan);

    Out.ar(
        0,
        resonz_signal;
    )
}).add;

		params = Dictionary.newFrom([
			\sinfm_index, 3,
			\sinfm_attack, 0,
			\sinfm_release, 0.4,
			\sinfm_phase, 0,
			\sinfm_amp, 0.2,
			\sinfm_pan, 0,
			\sinfm_modnum, 1,
			\sinfm_modeno, 1,			
			\ringer_index, 3,
			\ringer_amp, 0.2,
			\ringer_pan, 0,
			\karplu_index, 3,
			\karplu_coef, 0.5,
			\karplu_amp, 0.2,
			\karplu_pan, 0,
			\resonz_index, 0.1,
			\resonz_amp, 4,
			\resonz_pan, 0
		]);

		params.keysDo({ arg key;
			this.addCommand(key, "f", { arg msg;
				params[key] = msg[1];
			});
		});

		// this.addCommand("sinfm", "f", { arg msg;
		// 	Synth.new("sinfm", [\sinfm_carfreq, msg[1]] ++ params.getPairs)
		// });

		this.addCommand("sinfm", "f", { arg msg;			
			Synth.new("sinfm", [\sinfm_carfreq, msg[1]] ++ params.getPairs)
		});

		this.addCommand("ringer", "f", { arg msg;
			Synth.new("ringer", [\ringer_freq, msg[1]] ++ params.getPairs)
		});

		this.addCommand("karplu", "f", { arg msg;
			Synth.new("karplu", [\karplu_freq, msg[1]] ++ params.getPairs)
		});

		this.addCommand("resonz", "f", { arg msg;
			Synth.new("resonz", [\resonz_freq, msg[1]] ++ params.getPairs)
		});
	}
}
