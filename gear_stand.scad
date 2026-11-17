/*
 *  Parametric gear stand
 *
 *  Copyright (C) 2020 Adam Heinrich <adam@adamh.cz>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

include <Round-Anything/MinkowskiRound.scad>;

$fn = 250;

/**
 * VECTOR DIMENSIONS:
 *
 * Official case specs (from https://beetlecrab.audio/vector/)
 * Length: 290mm (Longest side)
 * Width: 180mm
 * Height: 50mm
 *
 * Distance from the inside of the rubber feet to the edge of the case: ~29mm
 * Distance from the nearest bolt to the rubber feet to the edge of the case: ~67mm
 * Thus, distance between the bolt to the rubber feet: 38mm (39mm has been verified to fit, with slack
 * so the 39 or 67 are off a bit)
 */

/* Gear geometry: */
gear_length = 290; // Case length, mm.
gear_width = 180; // Case width, mm.
gear_height = 50; // Case height, mm.
gear_size = 177; // Nominal gear dimension along the sloped support, mm.
gear_depth = 12; // Inset of the gear seating surface to help keep it from sliding, mm.

/* Stand geometry: */
stand_width = 39;
shear = 20;
angle = 28;
radius = 0;

/* Optional features */
have_brace = false;

/* Bottom rubber feet parameters
   MPN: 3M SJ5012 (7000001884): */
has_bottom_feet = true;
foot_diameter = 12.7 + 0.8;
foot_depth = 0.5;
foot_double = true;
foot_edge_distance = 1.5;

/* Anti-slip rubber parameters
   MPN: Fix & Fasten FIX-SF-152530: */
has_rubber = true;
rubber_w = 25 + 0.8;
rubber_h = 15 + 0.8;
rubber_z = 2.5;

/* Computed global variables: */
r2 = radius;
r1 = gear_depth - r2;

hyp = gear_size - gear_depth + r2;
x = hyp * cos(angle);
y = hyp * sin(angle);

module brace_cutout() {
    wood_height = 19.05;
    wood_width = 38.1;
    recess_depth = 20;
    pilot_diameter = 3;
    backing_depth = wood_height + 3;
    edge_offset = r1 + 2;
    back_start = [x + shear, 0];
    back_angle = atan2(y, -shear);
    outer_face = -r1;
    inner_face = backing_depth;
    pocket_center = (outer_face + inner_face) / 2;
    pocket_start = pocket_center - wood_height / 2;
    pocket_z = stand_width / 2 - recess_depth;
    pilot_z = pocket_z + recess_depth / 2;
    hole_depth = pocket_start - outer_face + 4;

    stand_inset = 67;
    brace_length = gear_length - 2 * stand_inset + 2 * recess_depth;
    echo(str("Brace length: ", brace_length, " mm"));

    translate([back_start[0], back_start[1], pocket_z])
        rotate([0, 0, back_angle])
            translate([edge_offset, pocket_start, 0])
                cube([wood_width, wood_height, recess_depth]);

    for (i = [-1, 1]) {
        hole_x = edge_offset + wood_width / 2 + i * (wood_width / 4);
        translate([back_start[0], back_start[1], pilot_z])
            rotate([0, 0, back_angle])
                translate([hole_x, outer_face, 0])
                    rotate([-90, 0, 0])
                        cylinder(d = pilot_diameter, h = hole_depth);
    }
}

module stand_2d() {
    pts=[[0, 0],
         [x + shear,0],
         [x, y]];

    difference() {
        minkowski() {
            difference() {
                /* Main body: */
                minkowski() {
                    polygon(pts);
                    circle(r = r1);
                }

                /* Cutout for the gear: */
                rotate(angle) {
                    translate([0, -r2]) {
                        square([gear_size, gear_depth + r2]);
                    }
                }
            }

            /* Extra rounding: */
            if (r2 > 0) {
                circle(r = r2);
            }
        }

        /* Inset triangle, with optional thickness at the short back edge: */
        dx = gear_depth / sin(angle);
        inset_scale = (x + shear - dx) / (x + shear);
        pts_inside_base = pts * inset_scale;
        brace_backing_depth = have_brace ? 19.05 + 3 : 0;
        back_edge_length = sqrt(shear * shear + y * y);
        back_tangent = [-shear / back_edge_length, y / back_edge_length];
        back_inward = [-back_tangent[1], back_tangent[0]];
        back_start = [x + shear - dx, 0];
        back_offset_start = back_start + back_inward * brace_backing_depth;
        base_intersection = back_offset_start +
                            back_tangent * (-back_offset_start[1] /
                                            back_tangent[1]);
        hyp_parameter = (back_offset_start[0] * back_tangent[1] -
                         back_offset_start[1] * back_tangent[0]) /
                        (x * back_tangent[1] - y * back_tangent[0]);
        hyp_intersection = [x * hyp_parameter, y * hyp_parameter];
        pts_inside = have_brace
            ? [
                pts_inside_base[0],
                base_intersection,
                hyp_intersection
              ]
            : pts_inside_base;

        /* Internal cutout: */
        translate([dx, 0]) {
            round2d(r2, 0) {
                polygon(pts_inside);
            }
        }
    }
}

module stand_3d() {
    union() {
        difference() {
            /* Main body: */
            minkowski() {
                linear_extrude(height = stand_width, center = true) {
                   stand_2d();
                }
            }
 
            /* Bottom feet: */
            if (has_bottom_feet) {
                for (i = [0, 1], j = [-1, 1]) {
                    dy = stand_width / 2 - foot_diameter / 2 - foot_edge_distance;
                    posy = foot_double ? j * dy : 0;
                    posx = (1 - 2 * i) * foot_diameter + i * (x + shear);

                    rotate([-90, 0, 0]) {
                        translate([posx, posy, -gear_depth]) {
                            cylinder(d = foot_diameter,
                                     h = foot_depth * 2,
                                     center = true);
                        }
                    }
                }
            }

            /* Anti-slip rubber on the hypotenuse: */
            if (has_rubber) {
                for (i = [0, 1]) {
                    posx = (1 - 2 * i) * (1.5 * rubber_h) + i * gear_size;

                    rotate([0, 0, angle]) {
                        translate([posx, -rubber_z/2, 0]) {
                            cube([rubber_h, rubber_z, rubber_w], center = true);
                        }
                    }
                }
            }

            /* Brace pocket and pilot holes: */
            if (have_brace) {
                brace_cutout();
            }
        }
    }
}

//stand_2d();
mirror([0, 0, 1]) stand_3d();
