#!/usr/bin/env swift

import Foundation

enum WeaponType {
    case machineGun(power: Int = 20, price: Int = 0)
    case torpedo(power: Int = 40, price: Int = 50)
    case rocket(power: Int = 80, price: Int = 100)
    case laser(power: Int = 100, price: Int = 200)
    
    static var weapons: [WeaponType] = [.machineGun(), .torpedo(), .rocket(), .laser()]
    
    static func getRandomWeapon(player: Player) -> WeaponType {
        if let weapon = weapons.randomElement(), weapon.price <= player.coins {
            return weapon
        }
        return .machineGun()
    }
    
    var name: String {
        switch self {
        case .machineGun: return "Пулемёт"
        case .torpedo: return "Торпеда"
        case .rocket: return "Ракета"
        case .laser: return "Лазер"
            
        }
    }

    var power: Int {
        switch self {
        case .torpedo(let power, _),
                .rocket(let power, _),
                .laser(let power, _),
                .machineGun(let power, _): return power
        }
    }
    
    var price: Int {
        switch self {
        case .torpedo(_, let price),
                .rocket(_, let price),
                .laser(_, let price),
                .machineGun(_, let price): return price
        }
    }
    
    var info: String {
        "\(name)(урон: \(power) цена: \(price) монет)"
    }
}

enum PlayerType {
    case Person
    case AI
}

enum BoardCreationOption {
    case addShipManually
    case generateBoardWithShips
}

struct CheckInputCoordinates {
    func handleInput(player: Player) -> Position {
        var input: String? = nil
        repeat {
            print("\(player.nick), введите координаты:")
            input = readLine()?.uppercased()
        } while !isValid(input)
        let row = Int(input!.prefix(while: {$0.isNumber}))!
        let col = Int(((input!.last)?.unicodeScalars.first?.value)!) - 1039
        let position = Position(row, col)
        return position
    }
    
    func isValid(_ input: String?) -> Bool {
        let rowArray = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
        let colArray = ["А", "Б", "В", "Г", "Д", "Е", "Ж", "З", "И", "Й"]
        var validPositionValues = [String]()
        for row in rowArray {
            for col in colArray {
                validPositionValues.append("\(row)\(col)")
            }
        }
        guard let input = input, !input.isEmpty, validPositionValues.contains(input.uppercased()) else {
            print("Неверные координаты, попробуйте снова.")
            return false
        }
        return true
    }
}

struct CheckInputCreationOption {
    func handleInput() -> String {
        var input: String? = readLine()
        while !isValid(input) {
            input = readLine()
        }
        return input!
    }
    func isValid(_ input: String?) -> Bool {
        guard let input = input, input.count == 1, input == "1" || input == "2" else {
            print("Команда не распознана. Попробуйте снова:)")
            return false
        }
        return true
    }
}
struct CreateBoard {
     func createBoard(player: inout Player, board: inout Board) {
         if !player.isAI {
             print("\(player.nick),\nнажмите 1 и Enter на клавиатуре, если хотите, чтобы игра случайным образом расположила корабли на карте. \nНажмите 2 и Enter, если хотите сами задавать координаты для каждого корабля.")
             let checkInput = CheckInputCreationOption()
             let input = checkInput.handleInput()
             switch input {
             case "1": player.createBoard(option: .generateBoardWithShips, board: &board)
             case "2": player.createBoard(option: .addShipManually, board: &board)
             default: return
            }
         }
         if player.isAI {
             player.createBoard(option: .generateBoardWithShips, board: &board)
         }
    }
}
struct AttackShip {
    func attackShip(player: inout Player, enemyBoard: inout Board) -> String {
        var position: Position = Position(-1, -1)
        if player.isAI {
            sleep(4)
            let x = Int.random(in: 1...10)
            let y = Int.random(in: 1...10)
            position = Position(x, y)
            while player.emptyEnemyPositions.contains(where: {$0 == position}) {
                let x = Int.random(in: 1...10)
                let y = Int.random(in: 1...10)
                position = Position(x, y)
            }
        } else {
            let weaponChoice = WeaponChoice()
            weaponChoice.chooseWeapon(player: &player)
            var checkInputCoordinates = CheckInputCoordinates()
            position = checkInputCoordinates.handleInput(player: player)
            while player.emptyEnemyPositions.contains(where: {$0 == position}) {
                print("Вы уже наносили удар по этим координатам, там короблей противника нет. Введите другие координаты!")
                checkInputCoordinates = CheckInputCoordinates()
                position = checkInputCoordinates.handleInput(player: player)
            }
        }
        let message = player.attackShip(enemyBoard: &enemyBoard, position: position)
        player.weapon = .machineGun()
        return message
    }
}

struct WeaponChoice {
    func chooseWeapon(player: inout Player) {
        guard !player.isAI else {
            player.weapon = WeaponType.getRandomWeapon(player: player)
            return
        }
        print("\(player.nick ), выберете оружие! У Вас сейчас \(player.weapon.name)")
        print("Если хотите сменить оружие, то нажмите 1 и Enter, если Вас оружие устраивает, то нажмиет 2 и Enter")
        let checkInput = CheckInputCreationOption()
        var i = 0
        var input = "0"
        while  true {
            input = checkInput.handleInput()
            if input == "2" {
                if !canBuy(player: &player, weapon: WeaponType.weapons[i]) {
                    continue
                }
                player.coins -= WeaponType.weapons[i].price
                break
            }
            i += 1
            if i == WeaponType.weapons.count {
                i = 0
            }
            print("\(WeaponType.weapons[i].info)")
        }
        player.weapon = WeaponType.weapons[i]
    }
    
    func canBuy(player: inout Player, weapon: WeaponType) -> Bool {
        guard player.coins >= weapon.price else {
            print("У Вас недостаточно монет для покупки данного оружия")
            return false
        }
        return true
    }
}

struct CreatePlayerAndBoard {
    mutating func createPlayerAndBoard(player1: inout Player, player2: inout Player, board1: inout Board, board2: inout Board, secondPlayer: PlayerType) {
        if secondPlayer == .Person {
            print("Игрок №1, введите Ваш ник:")
            let nickPlayer1 = readLine() ?? "Игрок №1"
            player1 = Player(_nick: nickPlayer1, _isAi: false)
            board1 = Board(_isAIBoard: false)
            print("Игрок №2, введите Ваш ник:")
            let nickPlayer2 = readLine() ?? "Игрок №2"
            player2 = Player(_nick: nickPlayer2, _isAi: false)
            board2 = Board(_isAIBoard: false)
            createBoard(player: &player1, board: &board1)
            createBoard(player: &player2, board: &board2)
        }
        if secondPlayer == .AI {
            print("Игрок, введите Ваш ник:")
            let nickPlayer1 = readLine() ?? "Я"
            player1 = Player(_nick: nickPlayer1, _isAi: false)
            board1 = Board(_isAIBoard: false)
            player2 = Player()
            board2 = Board()

            createBoard(player: &player1, board: &board1)
            createBoard(player: &player2, board: &board2)
        }
    }
    func createBoard(player: inout Player, board: inout Board) {
        let createBoard = CreateBoard()
        createBoard.createBoard(player: &player, board: &board)
    }
}
    
struct StartGame {
    mutating func startGame(player1: inout Player, player2: inout Player, board1: inout Board, board2: inout Board) {
        print("Будете играть с другом или против ИИ?\nНажмите 1 и Enter, если будете играть против ИИ.\nНажмите 2 и Enter, если будете играть с другом.")
        let checkInput = CheckInputCreationOption()
        let input = checkInput.handleInput()
        var createPlayerAndBoard = CreatePlayerAndBoard()
        switch input {
        case "1":
            createPlayerAndBoard.createPlayerAndBoard(player1: &player1, player2: &player2, board1: &board1, board2: &board2, secondPlayer: .AI)
        case "2":
            createPlayerAndBoard.createPlayerAndBoard(player1: &player1, player2: &player2, board1: &board1, board2: &board2, secondPlayer: .Person)
        default: return
        }
    }
}
struct PlayersState {
    func getPlayersState(player1: Player, player2: Player, board1: inout Board, board2: inout Board) {
        print("Игроки:\n  \(player1.nick) ------- \(player2.nick)")
        print("Состояние своих кораблей:\n  \(board1.getShipsState()) ------- \(board2.getShipsState())")
        print("Количество монет:\n  \(player1.coins) ------- \(player2.coins)")
    }
}

struct GameOver {
    func gameOver(board1: inout Board, board2: inout Board) -> Bool {
        board1.shipCount == 0 || board2.shipCount == 0
    }
}

struct Position {
    private var _row = 0
    private var _col = 0
    
    var row: Int {_row}
    var col: Int {_col}
    
    init(){}
    init(_ row: Int, _ col: Int) {
        _row = row
        _col = col
    }
}

extension Position {
    static func == (left: Position, right: Position) -> Bool {
        return left._row == right._row && left._col == right._col
    }
}

struct Ship {
    private var _position: Position
    private var _isSunk: Bool = false
    private var _appearance: String = ""
    private var _health = 100
    init(_position: Position, _isSunk: Bool = false, _appearance: String = "") {
        self._position = _position
        self._isSunk = _isSunk
        self._appearance = _appearance
    }
    
    var position: Position {
        get {_position}
        set {_position = newValue}
    }

    var health: Int {
        get {_health}
        set {_health = newValue}
    }
    var isSunk: Bool {
        get {_isSunk}
        set {_isSunk = newValue}
    }
    var appearance: String {
        get{
            switch _health {
            case ..<1: return "\u{26ab}"
            case 1..<25: return "\u{1f534}"
            case 25..<50: return  "\u{1F7E0}"
            case 50..<100: return "\u{1f7e1}"
            default: return "\u{1f7e2}"
            }
        }
        set {_appearance = newValue}
    }
}

struct Player {
    private var _nick = "Компьютер"
    private var _coins = 0
    private var _weapon: WeaponType = .machineGun()
    private var _emptyEnemyPositions: [Position] = []
    private var _isAI = true
    
    var emptyEnemyPositions: [Position] {
        get {_emptyEnemyPositions}
        set {_emptyEnemyPositions = newValue}
    }
    
    var nick: String {
        get {_nick}
        set {_nick = newValue}
    }
    var weapon: WeaponType {
        get {_weapon}
        set {_weapon = newValue}
    }
    var coins: Int {
        get {_coins}
        set {_coins = newValue}
    }
    
    var isAI: Bool {
        get {_isAI}
        set {_isAI = newValue}
    }
    init(_nick: String = "Компьютер", _isAi: Bool = true) {
        self._nick = _nick
        self._isAI = _isAi
    }
    
    mutating func attackShip(enemyBoard: inout Board, position: Position) -> String {
        for i in 0..<enemyBoard.ships.count {
            if enemyBoard.ships[i].position == position {
                if enemyBoard.ships[i].isSunk {
                    return "Данный корабль уже уничтожен!. Вы молодец, но стоит экономить снаряды, ведь битва ещё не окончена!"
                }
                enemyBoard.ships[i].health -= _weapon.power
                if enemyBoard.ships[i].health <= 0 {
                    enemyBoard.ships[i].isSunk = true
                    _coins += 100
                    enemyBoard.shipCount -= 1
                    return "Корабль врага уничтожен!. Поздравляем!!!"
                }
                if enemyBoard.ships[i].health > 0 {
                    _coins += 25
                    return "Корабль врага подбит!. Хороший выстрел!"
                }
            }
        }
        _emptyEnemyPositions.append(position)
        enemyBoard[position] = "\u{1f641}"
        return "К сожалению, цель не поражена, на данном участке карты кораблей противника нет!"
    }
    mutating func createBoard(option: BoardCreationOption, board: inout Board) {
        switch option {
        case .addShipManually: addShip(board: &board)
        case .generateBoardWithShips: board.generateBoardWithShips()
        }
    }
    
    private mutating func addShip(board: inout Board) {
        while board.ships.count < 10 {
            print("Пожалуйста, введите координаты позиции, в котрую Вы хотите установить корабль.Пример формата ввода: \"1A\" только без кавычек:)")
            board.showAllShips()
            board.printBoard()
            let checkInputCoordinates = CheckInputCoordinates()
            let position = checkInputCoordinates.handleInput(player: self)
            board.addShip(position: position)
            print("\u{001b}[H")
            for row in board.emptyArr2D {
                for col in row {print(col, terminator: " ")}
                print()
            }
            print("\u{001b}[H")
        }
        board.makeShipsInvisible()
    }
}

struct Board {
    private var _isAIBoard = true
    private var _arr2D = Array(repeating: Array(repeating: "\u{1f533}", count: 12), count: 12)
    private var _emptyArr2D = Array(repeating: Array(repeating: " ", count: 50), count: 100)
    var arr2D: [[String]] {_arr2D}
    var emptyArr2D: [[String]] {_emptyArr2D}
    private var _shipCount: Int = 10
    var isAIBoard: Bool {
        get {_isAIBoard}
        set {_isAIBoard = newValue}
    }
    var shipCount: Int {
        get {_shipCount}
        set {_shipCount = newValue}
    }
    var ships = [Ship]()
    init(_isAIBoard: Bool = true) {
        self._isAIBoard = _isAIBoard
        setBoardBorder()
    }

    mutating func addShip(position: Position){
        guard (canAddShip(position: position)) else {return}
        ships.append(Ship(_position: position))
        if !_isAIBoard {
            print("Корабль успешно установлен по данным координатам.")
            sleep(2)
        }
    }
    
    func canAddShip(position: Position) -> Bool {
        guard (!ships.contains{$0.position == position}) else {
            if !_isAIBoard {
                print("По данным координатам уже находится корабль. Пожалуйста, расположите свой корабль в другом месте!")
                sleep(2)
            }
            return false
        }
        return true
    }
    func getShipsState() -> String {
        var state = ""
        for ship in ships {
            state += ship.appearance
        }
        return state
    }
    
    mutating func makeShipsInvisible() {
        for ship in ships {
            let row = ship.position.row
            let col = ship.position.col
            _arr2D[row][col] = "\u{1f533}"
        }
    }
    
    mutating func showAllShips() {
        for ship in ships {
            let row = ship.position.row
            let col = ship.position.col
            _arr2D[row][col] = "\u{1f7e2}"
        }
    }
    
    mutating func showShips() {
        for ship in ships {
            if ship.health != 100 {
                let row = ship.position.row
                let col = ship.position.col
                _arr2D[row][col] = ship.appearance
            }
        }
    }
    mutating func setBoardBorder() {
        let leftColArray = [" %", " 1", " 2", " 3", " 4", " 5", " 6", " 7", " 8", " 9", "10", " %"]
        let rightColArray = ["%", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "%"]
        let colArray = [" %", " А", " Б", " В", " Г", " Д", " Е", " Ж", " З", " И", " Й", "%"]
        for i in 0...11 {
            self[i, 0] = leftColArray[i]
            self[i, 11] = rightColArray[i]
            self[0, i] = colArray[i]
            self[11, i] = colArray[i]
        }
    }
    mutating func generateBoardWithShips() {
        while ships.count < 10 {
            let row = Int.random(in: 1...10)
            let col = Int.random(in: 1...10)
            let position = Position(row, col)
            addShip(position: position)
        }
    }
    func printBoard() {
        print()
        for row in _arr2D {
            for col in row {print(col, terminator: "")}
            print()
        }
    }
}

extension Board {
    subscript(position: Position) -> String {
        get {_arr2D[position.row][position.col]}
        set {_arr2D[position.row][position.col] = newValue}
    }
    
    subscript(_ row: Int, _ col: Int) -> String {
        get {_arr2D[row][col]}
        set {_arr2D[row][col] = newValue}
    }
}

struct PlayGame {
    private var _emptyArr2D = Array(repeating: Array(repeating: " ", count: 50), count: 100)
    
    func clearConsole() {
        print("\u{001b}[H")
        for row in _emptyArr2D {
            for col in row {print(col, terminator: " ")}
            print()
        }
        print("\u{001b}[H")
    }
    
    func attackShip(player: inout Player, board: inout Board) -> String {
        let attackShip = AttackShip()
        return attackShip.attackShip(player: &player, enemyBoard: &board)
    }
    func printBoards(player1: inout Player, player2: inout Player, board1: inout Board, board2: inout Board, msg: String) {
        let playersState = PlayersState()
        clearConsole()
        playersState.getPlayersState(player1: player1, player2: player2, board1: &board1, board2: &board2)
        board1.showShips()
        board2.showShips()
        board1.printBoard()
        print("***Карта игрока \"\(player1.nick)\"***")
        board2.printBoard()
        print("***Карта игрока \"\(player2.nick)\"***")
        print(msg)
        sleep(2)
    }
    
    mutating func playGame(player1: inout Player, player2: inout Player, board1: inout Board, board2: inout Board) {
        let gameOver = GameOver()
        var message = ""
        while true {
            printBoards(player1: &player1, player2: &player2, board1: &board1, board2: &board2, msg: message)
            message = attackShip(player: &player1, board: &board2)
            printBoards(player1: &player1, player2: &player2, board1: &board1, board2: &board2, msg: message)
            if gameOver.gameOver(board1: &board1, board2: &board2) {break}
            message = attackShip(player: &player2, board: &board1)
            if gameOver.gameOver(board1: &board1, board2: &board2) {break}
        }
        let winner = board1.shipCount > 0 ? player1 : player2
        print("\(winner.nick), поздравляем Вас с Победой!!!")
    }
}

struct Game {
    var player1 = Player()
    var player2 = Player()
    var board1 = Board()
    var board2 = Board()
    var startGame = StartGame()
    var playGame = PlayGame()
        
    init() {
        startGame.startGame(player1: &player1, player2: &player2, board1: &board1, board2: &board2)
        playGame.playGame(player1: &player1, player2: &player2, board1: &board1, board2: &board2)
    }
}

var game = Game()
