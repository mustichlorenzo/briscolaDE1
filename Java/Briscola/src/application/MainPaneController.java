package application;

import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.scene.control.Alert;
import javafx.scene.control.Alert.AlertType;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.RadioButton;
import javafx.scene.control.TextField;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.BorderPane;
import javafx.scene.media.AudioClip;
import javafx.scene.paint.Color;
import javafx.scene.shape.Rectangle;
import javafx.stage.Stage;
import javafx.scene.effect.DropShadow;
import java.net.URL;
import java.util.Random;
import java.util.ResourceBundle;

import gnu.io.PortInUseException;

public class MainPaneController implements ReceiveCartaEventListener{
	private Carta receivedCarta;
	private InputParser parser;
	private SerialAdapter serialAdapter;
	private Mazzo mazzo;
	private String playerName;
	private boolean selectedCard1, selectedCard2, selectedCard3;
	private boolean startsPlayer;
	private boolean playedCard;
	private DropShadow borderGlow1, borderGlow2, borderGlow3;
	private GameTracker gameTracker;
	private Carta carta_giocata;
	private Alert signalFromFPGA;
	
	@FXML
	private Label playerNameGame;
	
	@FXML
	private Button playCardButton;
	
	@FXML
	private BorderPane startPane, gamePane, choosePane;
	
	@FXML
	private RadioButton playerRadioButton;
	
	@FXML
	private TextField playerNameTextArea;
	
	@FXML
	private ImageView imageBriscola;
	
	@FXML
	private ImageView cardImagePlayer1, cardImagePlayer2, cardImagePlayer3, cardImageComputer1, cardImageComputer2, cardImageComputer3;
	
	@FXML
	private ImageView cardPlayedPlayer, cardPlayedComputer;
	
	@FXML
	private Rectangle rectCPU, rectPlayer;
	
	@FXML
	private URL location;
	
	@FXML
	private ResourceBundle resources;
	
	public MainPaneController() {
		this.borderGlow1 = setBorderGlow();
		this.borderGlow2 = setBorderGlow();
		this.borderGlow3 = setBorderGlow();
		this.playerName = "Player 1";
		this.selectedCard1=false;
		this.selectedCard2=false;
		this.selectedCard3=false;
		this.playedCard=false;
		this.mazzo = new Mazzo();
		this.parser = new InputParser();
		this.parser.setEventListener(this);
		try {
			this.serialAdapter = new SerialAdapter(this.parser);
		} catch (PortInUseException e) {
			Alert alert = new Alert(AlertType.ERROR);
			alert.setTitle("Errore porta seriale!!!");
			alert.setHeaderText("Errore porta seriale!!!");
			alert.setContentText("Scollegare e ricollegare il cavo seriale dal PC!");
			alert.showAndWait();
			e.printStackTrace();
		}
		this.serialAdapter.listen();
	}
	
	private void setMano() {
			this.cardImagePlayer1.setImage(this.mazzo.getImageFromCarta(this.mazzo.getManoPlayer(startsPlayer).get(0)));
			this.cardImagePlayer2.setImage(this.mazzo.getImageFromCarta(this.mazzo.getManoPlayer(startsPlayer).get(1)));
			this.cardImagePlayer3.setImage(this.mazzo.getImageFromCarta(this.mazzo.getManoPlayer(startsPlayer).get(2)));
	}

	private DropShadow setBorderGlow() {
		DropShadow borderGlow = new DropShadow();
		borderGlow.setColor(Color.YELLOW);
		borderGlow.setOffsetX(0f);
		borderGlow.setOffsetY(0f);
		borderGlow.setHeight(150);
		borderGlow.setWidth(150);
		return borderGlow;
	}

	@FXML
	private void initialize() {
		startPane.setVisible(true);
		gamePane.setVisible(false);
		choosePane.setVisible(false);
	}
	
	@FXML
	protected void onClickStartButton(ActionEvent e) {
		if(playerNameTextArea.getText().isEmpty()) {
			Alert alert = new Alert(AlertType.ERROR);
			alert.setTitle("Nome del Giocatore mancante!!!");
			alert.setHeaderText("Nome del Giocatore mancante!!!");
			alert.setContentText("Inserire un nome del giocatore!!");
			alert.showAndWait();
		} else {
			this.playerName = playerNameTextArea.getText();
			startPane.setVisible(false);
			choosePane.setVisible(true);
			playerRadioButton.setText(playerName);
		}
		this.signalFromFPGA = new Alert(AlertType.WARNING);
		signalFromFPGA.setTitle("Sincronizzazione dei giocatori");
		signalFromFPGA.setHeaderText("Attesa della sincronizzazione dei giocatori");
		signalFromFPGA.setContentText("Premere il tasto KEY 3 sull'FPGA per proseguire");
		signalFromFPGA.show();
	}
	
	@FXML
	protected void onClickGiocaButton(ActionEvent e) {
		this.startsPlayer = playerRadioButton.isSelected();
		startPane.setVisible(false);
		choosePane.setVisible(false);
		gamePane.setVisible(true);
		playerNameGame.setText(playerName);
		imageBriscola.setImage(mazzo.getImageFromCarta(mazzo.getBriscola()));
		mazzo.setBriscole(mazzo.getBriscola());
		setMano();
		this.serialAdapter.sendMano(mazzo.getManoCPU(startsPlayer));
		this.serialAdapter.sendBriscola(mazzo.getBriscola());
		this.playCardButton.setDisable(!startsPlayer);
		this.gameTracker = new GameTracker(startsPlayer);
		this.parser.setGameTracker(this.gameTracker);
		this.serialAdapter.writeToSerialPort(this.gameTracker.getStarterToken());
		this.rectCPU.setVisible(!startsPlayer);
		this.rectPlayer.setVisible(startsPlayer);
	}
	
	@FXML
	protected void onMouseEnteredCard1(MouseEvent e) {
		this.cardImagePlayer1.setEffect(borderGlow1);
	}
	
	@FXML
	protected void onMouseEnteredCard2(MouseEvent e) {
		this.cardImagePlayer2.setEffect(borderGlow2);
	}
	
	@FXML
	protected void onMouseEnteredCard3(MouseEvent e) {
		this.cardImagePlayer3.setEffect(borderGlow3);
	}
	
	@FXML
	protected void onMouseExitedCard1(MouseEvent e) {
		if(!this.selectedCard1) this.cardImagePlayer1.setEffect(null);
	}
	
	@FXML
	protected void onMouseExitedCard2(MouseEvent e) {
		if(!this.selectedCard2) this.cardImagePlayer2.setEffect(null);
	}
	
	@FXML
	protected void onMouseExitedCard3(MouseEvent e) {
		if(!this.selectedCard3) this.cardImagePlayer3.setEffect(null);
	}
	
	@FXML
	protected void onClickCardPlayer1(MouseEvent e) {
		if(!this.selectedCard1) { 
			this.cardImagePlayer1.setEffect(borderGlow1);
			this.selectedCard1=true;
			this.cardImagePlayer2.setEffect(null);
			this.selectedCard2=false;
			this.cardImagePlayer3.setEffect(null);
			this.selectedCard3=false;
			if(!this.playedCard && this.gameTracker.getTurnoPlayer()) this.playCardButton.setDisable(false);
			else this.playCardButton.setDisable(true);
		}
		else {
			this.cardImagePlayer1.setEffect(null);
			this.selectedCard1=false;
			this.playCardButton.setDisable(true);
		}
	}

	@FXML
	protected void onClickCardPlayer2(MouseEvent e) {
		if(!this.selectedCard2) {
			this.cardImagePlayer1.setEffect(null);
			this.selectedCard1=false;
			this.cardImagePlayer2.setEffect(borderGlow2);
			this.selectedCard2=true;
			this.cardImagePlayer3.setEffect(null);
			this.selectedCard3=false;
			if(!this.playedCard && this.gameTracker.getTurnoPlayer()) this.playCardButton.setDisable(false);
			else this.playCardButton.setDisable(true);
		}
		else {
			this.cardImagePlayer2.setEffect(null);
			this.selectedCard2=false;
			this.playCardButton.setDisable(true);
		}
	}
	
	@FXML
	protected void onClickCardPlayer3(MouseEvent e) {
		if(!this.selectedCard3) {
			this.cardImagePlayer1.setEffect(null);
			this.selectedCard1=false;
			this.cardImagePlayer2.setEffect(null);
			this.selectedCard2=false;
			this.cardImagePlayer3.setEffect(borderGlow3);
			this.selectedCard3=true;
			if(!this.playedCard && this.gameTracker.getTurnoPlayer()) this.playCardButton.setDisable(false);
			else this.playCardButton.setDisable(true);
		}
		else { 
			this.cardImagePlayer3.setEffect(null);
			this.selectedCard3=false;
			this.playCardButton.setDisable(true);
		}
	}
	
	@FXML
	protected void onClickPlayCard (ActionEvent e) {
		//Audio
		AudioClip note = new AudioClip(this.getClass().getResource("CartaSbatte.wav").toString());
		note.play();
		int selectedCard = getSelectedCard();
		switch (selectedCard) {
		case 1:
			this.cardImagePlayer1.setEffect(null);
			this.cardImagePlayer1.setVisible(false);
			this.cardPlayedPlayer.setImage(this.cardImagePlayer1.getImage());
			break;
		case 2:
			this.cardImagePlayer2.setEffect(null);
			this.cardImagePlayer2.setVisible(false);
			this.cardPlayedPlayer.setImage(this.cardImagePlayer2.getImage());
			break;
		case 3:
			this.cardImagePlayer3.setEffect(null);
			this.cardImagePlayer3.setVisible(false);
			this.cardPlayedPlayer.setImage(this.cardImagePlayer3.getImage());
			break;
		}
		this.carta_giocata = this.mazzo.getManoPlayer(startsPlayer).get(selectedCard-1);
		this.serialAdapter.writeToSerialPort(this.parser.fromCartaToByte(carta_giocata));
		System.out.print(" --> " + carta_giocata.toString());
		this.serialAdapter.writeToSerialPort(this.gameTracker.getToken());
		this.playedCard = true;
		this.playCardButton.setDisable(true);
		this.gameTracker.invertiTurno();
		this.rectCPU.setVisible(!this.gameTracker.getTurnoPlayer());
		this.rectPlayer.setVisible(this.gameTracker.getTurnoPlayer());
	}

	private int getSelectedCard() {
		if(this.selectedCard1) return 1;
		if(this.selectedCard2) return 2;
		if(this.selectedCard3) return 3;
		return 0;
	}

	@Override
	public void onReceiveCarta(Carta c) {
		if(!c.equals(this.receivedCarta)) {
			if(c.getValore()!=0 && this.mazzo.manoCPUContains(startsPlayer, c)) {
				//Audio
				AudioClip note = new AudioClip(this.getClass().getResource("CartaSbatte.wav").toString());
				note.play();
				this.receivedCarta = c;
				this.cardPlayedComputer.setImage(this.mazzo.getImageFromCarta(this.receivedCarta));
				Random r = new Random();
				int index = r.nextInt(3) + 1;
				switch (index) {
				case 1: this.cardImageComputer1.setVisible(false); break;
				case 2: this.cardImageComputer2.setVisible(false); break;
				case 3: this.cardImageComputer3.setVisible(false); break;
				}
				if(!this.gameTracker.getPresaValutata() && !this.playedCard ) {	//token per forzare lo stato di attesa della CPU
					this.serialAdapter.writeToSerialPort(this.gameTracker.getACKTokenCPU());
					this.rectCPU.setVisible(false);
					this.rectPlayer.setVisible(true);
				}
				this.playCardButton.setDisable(this.gameTracker.getTurnoPlayer());
			}
		
		} else { this.receivedCarta = null; }
		if(this.gameTracker.getPresaValutata() && this.receivedCarta != null) {
			this.playedCard = false;
			System.out.println("\n---------- NUOVO TURNO ----------");
			if(this.gameTracker.getPrendePlayer()) {	//imposto il gametracker per il prossimo turno
				this.mazzo.getManoPlayer(startsPlayer).remove(carta_giocata);
				Carta next_card_player = this.mazzo.getNextCard();
				this.mazzo.getManoPlayer(startsPlayer).add(next_card_player);
				switch(getPlayedCard()) {
				case 1: this.cardImagePlayer1.setImage(this.mazzo.getImageFromCarta(next_card_player)); break;
				case 2: this.cardImagePlayer2.setImage(this.mazzo.getImageFromCarta(next_card_player)); break;
				case 3: this.cardImagePlayer3.setImage(this.mazzo.getImageFromCarta(next_card_player)); break;
				}
				
				this.mazzo.removeCarta(this.mazzo.getManoCPU(startsPlayer),this.receivedCarta);
				Carta next_card_CPU = this.mazzo.getNextCard();
				this.mazzo.getManoCPU(startsPlayer).add(next_card_CPU);
				switch(getPlayedCardCPU()) {
				case 1: this.cardImageComputer1.setVisible(true); break;
				case 2: this.cardImageComputer2.setVisible(true); break;
				case 3: this.cardImageComputer3.setVisible(true); break;
				}
				this.gameTracker.nuovoTurno();
				this.serialAdapter.writeToSerialPort(this.gameTracker.getResetToken());
				this.serialAdapter.sendNextCard(next_card_CPU);
				
				this.playCardButton.setDisable(false);
				this.rectPlayer.setVisible(true);
				this.rectCPU.setVisible(false);
			} else {	//ha preso la CPU
				this.gameTracker.nuovoTurno();
				this.mazzo.removeCarta(this.mazzo.getManoCPU(startsPlayer),this.receivedCarta);
				Carta next_card_CPU = this.mazzo.getNextCard();
				this.mazzo.getManoCPU(startsPlayer).add(next_card_CPU);
				switch(getPlayedCardCPU()) {
				case 1: this.cardImageComputer1.setVisible(true); break;
				case 2: this.cardImageComputer2.setVisible(true); break;
				case 3: this.cardImageComputer3.setVisible(true); break;
				}
				
				this.mazzo.getManoPlayer(startsPlayer).remove(carta_giocata);
				Carta next_card_player = this.mazzo.getNextCard();
				this.mazzo.getManoPlayer(startsPlayer).add(next_card_player);
				switch(getPlayedCard()) {
				case 1: this.cardImagePlayer1.setImage(this.mazzo.getImageFromCarta(next_card_player)); this.cardImagePlayer1.setVisible(true); break;
				case 2: this.cardImagePlayer2.setImage(this.mazzo.getImageFromCarta(next_card_player)); this.cardImagePlayer2.setVisible(true); break;
				case 3: this.cardImagePlayer3.setImage(this.mazzo.getImageFromCarta(next_card_player)); this.cardImagePlayer3.setVisible(true); break;
				}
				this.serialAdapter.writeToSerialPort(this.gameTracker.getResetToken());
				this.serialAdapter.sendNextCard(next_card_CPU);

				this.rectPlayer.setVisible(false);
				this.rectCPU.setVisible(true);
			}
			this.cardPlayedComputer.setImage(null);
			this.cardPlayedPlayer.setImage(null);
			this.receivedCarta = null;
			this.carta_giocata = null;
		} else {
			this.gameTracker.invertiTurno();
		}
	}

	private int getPlayedCard() {
		if(!this.cardImagePlayer1.isVisible()) return 1;
		if(!this.cardImagePlayer2.isVisible()) return 2;
		if(!this.cardImagePlayer3.isVisible()) return 3;
		return 0;
	}
	
	private int getPlayedCardCPU() {
		if(!this.cardImageComputer1.isVisible()) return 1;
		if(!this.cardImageComputer2.isVisible()) return 2;
		if(!this.cardImageComputer3.isVisible()) return 3;
		return 0;
	}

	@Override
	public void onReceiveSincronizeSignal() {
		// TODO Auto-generated method stub
		
	}
	
	
}
