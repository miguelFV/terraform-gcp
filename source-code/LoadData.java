package com.example;

import com.example.Example.GCSEvent;
import com.google.cloud.functions.BackgroundFunction;
import com.google.cloud.functions.Context;
import java.util.logging.Logger;

public class LoadData implements BackgroundFunction<GCSEvent> {
  private static final Logger logger = Logger.getLogger(Example.class.getName());

  @Override
  public void accept(GCSEvent event, Context context) {
    logger.debug("Processing "+this.toString);
    logger.info("Processing file: " + event.name);

  }

  public static class GCSEvent {
    String bucket;
    String name;
    String metageneration;

    public String toString(){
      return "GCSEvent[bucket="+this.bucket+", name="+this.name+",  metageneration="+this.metageneration+"]";
    }
  }
}
