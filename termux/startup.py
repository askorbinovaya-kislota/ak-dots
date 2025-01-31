# disable python history, also don't import readline into interpreter
__import__("readline").write_history_file = lambda x: None;
