package application;

public class GameTracker {				//dato lo stato della partita, genera il token
	private boolean turnoPlayer;
	private boolean presaValutata;
	private boolean prendePlayer;
	
	public GameTracker(boolean turnoPlayer) {
		this.turnoPlayer = turnoPlayer;
		this.presaValutata = false;
	}

	public boolean getTurnoPlayer() {
		return turnoPlayer;
	}

	public void setTurnoPlayer(boolean turnoPlayer) {
		this.turnoPlayer = turnoPlayer;
	}

	public boolean getPresaValutata() {
		return presaValutata;
	}

	public void setPresaValutata(boolean presaValutata) {
		this.presaValutata = presaValutata;
	}
	
	public boolean getPrendePlayer() {
		return prendePlayer;
	}

	public void setPrendePlayer(boolean prendePlayer) {
		this.prendePlayer = prendePlayer;
	}

	public byte getStarterToken() {
		if(this.turnoPlayer) return 0x05;			//-->	token = 0000 0101	(Inizia il giocatore)
		else return 0x75;							//--> 	token = 0111 0101	(Inizia la CPU)
	}
	public byte getToken() {
		// Tocca al giocatore e la presa non è ancora stata valutata 				--> token = 0111 0101
		if(this.turnoPlayer && !this.presaValutata) return 0x75;
		// Tocca al giocatore, la presa è stata valutata e prende il giocatore 		-->	token = 0111 0000
		if(this.turnoPlayer && this.presaValutata && this.prendePlayer) return 0x70;
		// Tocca al giocatore, la presa è stata valutata e prende la CPU		 	-->	token = 0111 1111
		if(this.turnoPlayer && this.presaValutata && !this.prendePlayer) return 0x7F;
		// Non tocca al giocatore e la presa non è ancora stata valutata 			-->	token = 0000 0101
		if(!this.turnoPlayer && !this.presaValutata) return 0x05;
		// Non tocca al giocatore, la presa è stata valutata e prende il giocatore	-->	token = 0000 1111
		if(!this.turnoPlayer && this.presaValutata && this.prendePlayer) return 0x0F;
		// Non tocca al giocatore, la presa è stata valutata e prende la CPU		--> token = 0000 0000
		if(!this.turnoPlayer && this.presaValutata && !this.prendePlayer) return 0x00;
		return (byte) 0xFF;
	}
	
	public void invertiTurno() {
		this.turnoPlayer = !this.turnoPlayer;
	}

	public void nuovoTurno() {
		this.setPresaValutata(false);
		this.setTurnoPlayer(this.prendePlayer);
	}

	public byte getACKTokenCPU() {
		return (byte) 0x07;
	}
	
}
