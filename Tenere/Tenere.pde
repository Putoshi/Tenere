/**
 * Welcome to TÉNÉRÉ! Click the play button in the top left to give it a whirl.
 * The best place to get started with developing is a visit to the "Tutorial" tab.
 * There is code for an example pattern there, which gives some guidance.
 */
 
// Helpful global constants
final static float INCHES = 5;
final static float IN = INCHES;
final static float FEET = 12*INCHES;
final static float FT = FEET;
final static int _width = 1200;
final static int _height = 960;
final static byte OPC_CHANNEL_FOUR = 4;
// Our engine and our model
LXStudio lx;
Tree tree;
Sensors sensors;
PApplet applet = Tenere.this;

// Global UI objects
UITreeStructure uiTreeStructure;
UILeaves uiLeaves;
UITreeControls uiTreeControls;

// Processing's main invocation, build our model and set up LX
void setup() {
  size(1200, 960, P3D);
  final Timer t = new Timer();
  tree = buildTree();
  t.log("Built Tree Model");
  try {
    lx = new LXStudio(this, tree, false) {
      public void initialize(LXStudio lx, LXStudio.UI ui) {
        // Register a couple top-level effects
        lx.registerEffect(BlurEffect.class);
        lx.registerEffect(DesaturationEffect.class);        
        
        // Register the settings component
        lx.engine.registerComponent("tenereSettings", new Settings(lx, ui));
        
        // Register the sensor integrations
        sensors = new Sensors(lx);
        lx.engine.registerComponent("sensors", sensors);
        lx.engine.addLoopTask(sensors);
        
        // End-to-end test, sending one branch worth of data
        // 8 assemblages, 15 leaves, 7 leds = 840 points = 2,520 RGB bytes = 2,524 OPC bytes
        try {
          // Update appropriately for testing!
          final String OPC_ADDRESS = "192.168.1.80"; 
          //final String OPC_ADDRESS_2 = "192.168.1.80"; 
          final int OPC_PORT = 1337;
          
          final int PIXELS_PER_LEAF = Leaf.NUM_LEDS;
          // final int PIXELS_PER_LEAF = 1; // Use this version to test one value per leaf 
          
          // Construct list of output points to go in the datagram
          Branch branch = tree.branches.get(0); // Just test the first branch
          int li = 0;
          int li2 =0;
          int[] branchIndices = new int[(branch.leaves.size()* PIXELS_PER_LEAF)/2];
          int[] branchIndices2 = new int[(branch.leaves.size()* PIXELS_PER_LEAF)/2];
          int leafNum = 0;
          for (Leaf leaf : branch.leaves) {
            if (leafNum < branch.leaves.size()/2) {
            for (int i = 0; i < Leaf.NUM_LEDS; ++i) {
              branchIndices[li++] = leaf.point.index;
            }
          }
           else {
            for (int j = 0; j< Leaf.NUM_LEDS; ++j) {
              branchIndices2[li2++] = leaf.point.index;
              println("branchIndices2: " + branchIndices2 + "leaf point index " + leaf.point.index);
              }

           }
            leafNum++;
          }
          
          // Add a new datagram output driver with the branch datagram message
          lx.engine.output.addChild(new LXDatagramOutput(lx).addDatagram(
            new OPCDatagram(branchIndices, OPC_CHANNEL_FOUR)
            .setAddress(OPC_ADDRESS)
            .setPort(OPC_PORT)

          ));

          lx.engine.output.addChild(new LXDatagramOutput(lx).addDatagram(
            new OPCDatagram(branchIndices, OPCConstants.CHANNEL_BROADCAST)
            .setAddress(OPC_ADDRESS)
            .setPort(OPC_PORT)

          ));
        } catch (Exception x) {
          println("Failed to construct UDP output: " + x);
          x.printStackTrace();
        }
        
        t.log("Initialized LXStudio");
      }
      
      public void onUIReady(LXStudio lx, LXStudio.UI ui) {
        ui.preview.setRadius(80*FEET).setPhi(-PI/18).setTheta(PI/12);
        ui.preview.setCenter(0, model.cy - 2*FEET, 0);
        ui.preview.addComponent(new UISimulation());
        ui.preview.addComponent(uiLeaves = new UIShapeLeaves());
        ui.preview.pointCloud.setVisible(false);
        uiTreeStructure.setVisible(false);
        
        // Narrow angle lens, for a fuller visualization
        ui.preview.perspective.setValue(30);

        // Sensor integrations
        new UISensors(ui, ui.leftPane.global.getContentWidth()).addToContainer(ui.leftPane.global);
        
        // Custom tree rendering controls
        uiTreeControls = (UITreeControls) new UITreeControls(ui).addToContainer(ui.leftPane.global);        
        
        t.log("Initialized LX UI");
      }
    };
  } catch (Exception x) {
    println("Initialization error: " + x);
    x.printStackTrace();
  }
}

private class Settings extends LXComponent {
  
  private final LXStudio.UI ui;
  
  private Settings(LX lx, LXStudio.UI ui) {
    super(lx);
    this.ui = ui;
  }
  
  private static final String KEY_POINTS_VISIBLE = "pointsVisible";
  private static final String KEY_LEAVES_VISIBLE = "leavesVisible";
  private static final String KEY_STRUCTURE_VISIBLE = "structureVisible";
  private static final String KEY_CONTROLS_EXPANDED = "controlsExpanded";
  
  @Override
  public void save(LX lx, JsonObject obj) {
    obj.addProperty(KEY_POINTS_VISIBLE, this.ui.preview.pointCloud.isVisible());
    obj.addProperty(KEY_LEAVES_VISIBLE, uiLeaves.isVisible());
    obj.addProperty(KEY_STRUCTURE_VISIBLE, uiTreeStructure.isVisible());
    obj.addProperty(KEY_CONTROLS_EXPANDED, uiTreeControls.isExpanded());
  }
  
  @Override
  public void load(LX lx, JsonObject obj) {
    if (obj.has(KEY_POINTS_VISIBLE)) {
      uiTreeControls.pointsVisible.setActive(obj.get(KEY_POINTS_VISIBLE).getAsBoolean());
    }
    if (obj.has(KEY_LEAVES_VISIBLE)) {
      uiTreeControls.leavesVisible.setActive(obj.get(KEY_LEAVES_VISIBLE).getAsBoolean());
    }
    if (obj.has(KEY_STRUCTURE_VISIBLE)) {
      uiTreeControls.structureVisible.setActive(obj.get(KEY_STRUCTURE_VISIBLE).getAsBoolean());
    }
    if (obj.has(KEY_CONTROLS_EXPANDED)) {
      uiTreeControls.setExpanded(obj.get(KEY_CONTROLS_EXPANDED).getAsBoolean());
    }
  }
}

class CameraPosition {
  final float radius;
  final float theta;
  final float phi;
  
  public CameraPosition(float radius, float theta, float phi) {
    this.radius = radius;
    this.theta = theta;
    this.phi = phi;
  }
  
  public void set(UI3dContext context) {
    context.setRadius(this.radius).setTheta(this.theta).setPhi(this.phi);
  }
}

final CameraPosition[] cameraPositions = {
  new CameraPosition(120*FEET, PI/6, -PI/24),
  new CameraPosition(90*FEET, -PI/6, -PI/12),
  new CameraPosition(90*FEET, -PI/6, -PI/12),
  new CameraPosition(90*FEET, -PI/6, -PI/12),
  new CameraPosition(90*FEET, -PI/6, -PI/12),
  new CameraPosition(90*FEET, -PI/6, -PI/12),
  new CameraPosition(90*FEET, -PI/6, -PI/12),
  new CameraPosition(90*FEET, -PI/6, -PI/12),
  new CameraPosition(90*FEET, -PI/6, -PI/12),
  new CameraPosition(90*FEET, -PI/6, -PI/12)
};

float cameraInterp = 1;
CameraPosition currentCamera = cameraPositions[0];
CameraPosition targetCamera = cameraPositions[0];

void draw() {
  // LX handles everything for us!
  if (cameraInterp < 1) {
    cameraInterp += .001;
    cameraInterp = min(1, cameraInterp);
    lx.ui.preview
      .setRadius(lerp(currentCamera.radius, targetCamera.radius, cameraInterp))
      .setTheta(lerp(currentCamera.theta, targetCamera.theta, cameraInterp*cameraInterp))
      .setPhi(lerp(currentCamera.phi, targetCamera.phi, cameraInterp));
  } else {
    currentCamera = targetCamera;
  }
   
}

void keyPressed(KeyEvent keyEvent) {
  if (key == 'z') {
    // Little utility to get a bit of trace info from the engine
    lx.engine.logTimers();
  } else if (key >= '0' && key <= '9') {
    int cameraIndex = key - '0';
    if (cameraIndex < cameraPositions.length) {
      if (keyEvent.isControlDown() || keyEvent.isMetaDown()) {
        cameraPositions[cameraIndex] = new CameraPosition(
          lx.ui.preview.radius.getValuef(),
          lx.ui.preview.theta.getValuef(),
          lx.ui.preview.phi.getValuef()
        );
        currentCamera = targetCamera = cameraPositions[cameraIndex];
        cameraInterp = 1;
        println("Stored camera position " + cameraIndex);
      } else {
        cameraInterp = 0;
        targetCamera = cameraPositions[cameraIndex];
        println("Moving camera to position " + cameraIndex);
      }
    }
  } else if (key == 'c') {
    cameraInterp = 1;
    println("Manual camera control");
  }
}

private class Timer {
  private long last;
  
  Timer() {
    this.last = millis();
  }
  
  void log(String event) {
    long now = millis();
    println(event + ": " + (now - last) + "ms");
    this.last = now;
  }
  
}