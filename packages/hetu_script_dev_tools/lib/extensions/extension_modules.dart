part of hetu_script_dev_tools;

final Map<String, String> extensionModules = const {
  'hetu:console': r'''external class Console {
	// write a line without return
	static fun write(line: str)
	
	// write a line ends with return
	static fun writeln(line: str)
	
	static fun getln(info: str) -> str
	
	static fun eraseLine()
	
	static fun setTitle(title: str)
	
	static fun cls()
}
'''
};
