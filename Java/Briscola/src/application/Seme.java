package application;

public enum Seme {
	BASTONI("basto"),
	DENARI("denar"),
	COPPE("coppe"),
	SPADE("spade");
	
	private final String semeString;
	
	private Seme(String value) {
		semeString = value;
	}
	
	public String toString() {
		return semeString;
	}
}
