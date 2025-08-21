import meta from "../../../pages/_meta.js";
import archive_meta from "../../../pages/archive/_meta.js";
import archive_scum_v23_meta from "../../../pages/archive/scum-v23/_meta.js";
export const pageMap = [{
  data: meta
}, {
  name: "api-reference",
  route: "/api-reference",
  frontMatter: {
    "sidebarTitle": "API Reference"
  }
}, {
  name: "archive",
  route: "/archive",
  children: [{
    data: archive_meta
  }, {
    name: "scum-v23",
    route: "/archive/scum-v23",
    children: [{
      data: archive_scum_v23_meta
    }, {
      name: "digital-core",
      route: "/archive/scum-v23/digital-core",
      frontMatter: {
        "title": "Digital Core",
        "description": "Digital Core architecture and specifications for SCuM-V23"
      }
    }, {
      name: "encryption-modules",
      route: "/archive/scum-v23/encryption-modules",
      frontMatter: {
        "title": "Encryption Modules",
        "description": "Cryptographic acceleration modules including ECC, AES, and SHA-256"
      }
    }, {
      name: "index",
      route: "/archive/scum-v23",
      frontMatter: {
        "title": "SCuM-V23 Specification",
        "description": "Complete specification for the SCuM-V23 system-on-chip"
      }
    }, {
      name: "oscillators",
      route: "/archive/scum-v23/oscillators",
      frontMatter: {
        "title": "Oscillators",
        "description": "Clock generation and oscillator systems in SCuM-V23"
      }
    }, {
      name: "overview",
      route: "/archive/scum-v23/overview",
      frontMatter: {
        "title": "Overview",
        "description": "Overview of the SCuM-V23 System-on-Chip"
      }
    }, {
      name: "radar",
      route: "/archive/scum-v23/radar",
      frontMatter: {
        "title": "94 GHz FMCW Radar Transmitter",
        "description": "Frequency-modulated continuous wave radar transmitter operating at 94 GHz"
      }
    }, {
      name: "radio",
      route: "/archive/scum-v23/radio",
      frontMatter: {
        "title": "2.4 GHz Transceiver",
        "description": "2.4 GHz radio transceiver architecture and specifications"
      }
    }]
  }]
}, {
  name: "bootloading-guide",
  route: "/bootloading-guide",
  frontMatter: {
    "sidebarTitle": "Bootloading Guide"
  }
}, {
  name: "digital-baseband",
  route: "/digital-baseband",
  frontMatter: {
    "title": "Digital Baseband-Modem",
    "description": "Dual-Mode Baseband-Modem for Bluetooth LE and IEEE 802.15.4 for SCuM-V24B"
  }
}, {
  name: "digital-core",
  route: "/digital-core",
  frontMatter: {
    "title": "Digital Core",
    "description": "Digital Core architecture and specifications for SCuM-V24B"
  }
}, {
  name: "firmware-development",
  route: "/firmware-development",
  frontMatter: {
    "sidebarTitle": "Firmware Development"
  }
}, {
  name: "fpga-setup",
  route: "/fpga-setup",
  frontMatter: {
    "sidebarTitle": "Fpga Setup"
  }
}, {
  name: "hardware-setup",
  route: "/hardware-setup",
  frontMatter: {
    "sidebarTitle": "Hardware Setup"
  }
}, {
  name: "index",
  route: "/",
  frontMatter: {
    "title": "SCuM-V Bringup & Development",
    "description": "Complete toolkit for bringing up and developing with the Single-Chip Micro Mote V"
  }
}, {
  name: "oscillators",
  route: "/oscillators",
  frontMatter: {
    "title": "Oscillators",
    "description": "Clock generation and oscillator systems in SCuM-V24B"
  }
}, {
  name: "overview",
  route: "/overview",
  frontMatter: {
    "title": "Overview",
    "description": "Overview of the SCuM-V24B System-on-Chip"
  }
}, {
  name: "power-system",
  route: "/power-system",
  frontMatter: {
    "title": "Power System",
    "description": "Power management system including switched capacitor converter, LDOs, and reference circuits for SCuM-V24B"
  }
}, {
  name: "radar",
  route: "/radar",
  frontMatter: {
    "title": "94 GHz FMCW Radar Transmitter",
    "description": "Frequency-modulated continuous wave radar transmitter operating at 94 GHz"
  }
}, {
  name: "radio",
  route: "/radio",
  frontMatter: {
    "title": "2.4 GHz Transceiver",
    "description": "2.4 GHz radio transceiver architecture and specifications"
  }
}, {
  name: "uv-adc",
  route: "/uv-adc",
  frontMatter: {
    "title": "UV-Precision Delta-Sigma ADC",
    "description": "High-precision delta-sigma ADC designed for EEG front-end applications for SCuM-V24B"
  }
}];