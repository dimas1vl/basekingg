fx_version 'bodacious'
game { 'gta5' }

this_is_a_map 'yes'

files {
	'data/*.meta',
	'data/**/*.meta',
    'stream/*.meta',
    'dlc/*.meta',
    "dlc_arena/*.awc",
    "timecycles/*.xml"
}



data_file "AUDIO_WAVEPACK" "dlc_arena"
data_file "AUDIO_SOUNDDATA" "data/arena.dat"
data_file "TIMECYCLEMOD_FILE" "timecycles/*.xml"

data_file 'TIMECYCLEMOD_FILE' 'stream/timecycle/timecycle_mods.xml'
