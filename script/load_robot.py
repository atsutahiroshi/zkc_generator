from cnoid.Base import RootItem, ItemTreeView
from cnoid.BodyPlugin import BodyItem, SimulationBar


ROBOT_FILE_NAME = ""


def load_robot(filename):
    robotItem = BodyItem()
    robotItem.load(filename)
    robotItem.storeInitialState()
    worldItem = RootItem.instance().findItem("World")
    floorItem = RootItem.instance().findItem("Floor")
    worldItem.insertChildItem(robotItem, floorItem)

    ItemTreeView.instance().checkItem(robotItem)


def start_simulation():
    simulatorItem = RootItem.instance().findItem("RokiSimulator")
    ItemTreeView.instance().selectItem(simulatorItem)
    SimulationBar.instance().startSimulation(True)


def main():
    load_robot(ROBOT_FILE_NAME)
    start_simulation()


if __name__ == '__main__':
    main()
