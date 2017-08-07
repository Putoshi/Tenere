public class ColorSpread extends TenerePattern {
  public String getAuthor() {
    return "Mark C. Slee";
  }
  
  public ColorSpread(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs) {
    float hue = palette.getHuef();
    float sat = palette.getSaturationf();
    float spreadX = palette.spreadX.getValuef();
    float spreadY = palette.spreadY.getValuef();
    float spreadZ = palette.spreadZ.getValuef();
    float offsetX = palette.offsetX.getValuef();
    float offsetY = palette.offsetY.getValuef();
    float offsetZ = palette.offsetZ.getValuef();
    boolean mirror = palette.mirror.isOn();
    for (Leaf leaf : tree.leaves) {
      float dx = leaf.point.xn - .5 - offsetX;
      float dy = leaf.point.yn - .5 - offsetY;
      float dz = leaf.point.zn - .5 - offsetZ;
      if (mirror) {
        dx = abs(dx);
        dy = abs(dy);
        dz = abs(dz);
      }
      setColor(leaf, LXColor.hsb(
        hue + spreadX*dx + spreadY*dy + spreadZ*dz,
        sat,
        100
      ));
    }
  }
}

public class ColorAutumn extends TenerePattern {
  public String getAuthor() {
    return "Mark C. Slee";
  }
  
  public final CompoundParameter range = new CompoundParameter("Range", 30, 15, 45); 
  
  public ColorAutumn(LX lx) {
    super(lx);
    addParameter("range", this.range);
  }
  
  public void run(double deltaMs) {
    float sat = palette.getSaturationf();
    int li = 0;
    int range = (int) this.range.getValuef();
    for (Leaf leaf : tree.leaves) {
      setColor(leaf, LXColor.hsb(li % range, sat, 100));
      ++li;
    }
  }
}

public class ColorSwirl extends TenerePattern {
  public String getAuthor() {
    return "Mark C. Slee";
  }
    
  private float basis = 0;
  
  public final CompoundParameter speed =
    new CompoundParameter("Speed", .5, 0, 20);
      
  public final CompoundParameter slope = 
    new CompoundParameter("Slope", 1, .2, 3);    
    
  public final DiscreteParameter amount =
    new DiscreteParameter("Amount", 3, 1, 5)
    .setDescription("Amount of swirling around the center");    
  
  public ColorSwirl(LX lx) {
    super(lx);
    addParameter("speed", this.speed);
    addParameter("slope", this.slope);
    addParameter("amount", this.amount);
  }
  
  public void run(double deltaMs) {
    this.basis = (float) (this.basis + .001 * speed.getValuef() * deltaMs) % TWO_PI;
    float slope = this.slope.getValuef();
    float sat = palette.getSaturationf();
    int amount = this.amount.getValuei();
    for (Leaf leaf : tree.leaves) {
      float hb1 = (this.basis + leaf.point.azimuth - slope * (1 - leaf.point.yn)) / TWO_PI;
      setColor(leaf, LXColor.hsb(
        (this.basis + leaf.point.azimuth - slope * (1 - leaf.point.yn)) / TWO_PI * 360 * amount,
        sat,
        100
      )); 
    }
  }
}