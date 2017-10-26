from cnoid.Base import RootItem, ItemTreeView
from cnoid.BodyPlugin import BodyItem, SimulationBar, SimulatorItem
import time


ROBOT_FILE_NAME = ""


def load_robot(filename):
    robotItem = BodyItem()
    robotItem.load(filename)
    robotItem.storeInitialState()
    worldItem = RootItem.instance().findItem("World")
    floorItem = RootItem.instance().findItem("Floor")
    worldItem.insertChildItem(robotItem, floorItem)
    ItemTreeView.instance().checkItem(robotItem)
    return robotItem


def start_simulation():
    simulatorItem = RootItem.instance().findItem("RokiSimulator")
    ItemTreeView.instance().selectItem(simulatorItem)
    SimulationBar.instance().startSimulation(True)


def stop_simulation(robotItem):
    simulatorItem = SimulatorItem.findActiveSimulatorItemFor(robotItem)
    simulatorItem.stopSimulation()


def main():
    robot = load_robot(ROBOT_FILE_NAME)
    start_simulation()
    time.sleep(0.1)
    stop_simulation(robot)


if __name__ == '__main__':
    main()
