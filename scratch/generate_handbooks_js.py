import os

handbooks_path = r"c:\Users\china\Documents\AgriBase-Websites\assets\handbooks.js"

# 1. Read existing handbooks.js to preserve understanding-soil-ph, tomato-fertilizer-guide, farm-record-keeping, farming-dry-conditions
with open(handbooks_path, "r", encoding="utf-8") as f:
    current = f.read()

# Extract understanding-soil-ph
ph_start = current.find("replace('understanding-soil-ph'")
ph_end = current.find("replace('farm-record-keeping'")
if ph_start != -1 and ph_end != -1:
    understanding_soil_ph_code = current[ph_start:ph_end].strip()
else:
    understanding_soil_ph_code = ""

# Extract tomato-fertilizer-guide if separate or inside
tom_start = current.find("replace('tomato-fertilizer-guide'")
rec_start = current.find("replace('farm-record-keeping'")
if tom_start != -1 and rec_start != -1:
    tomato_guide_code = current[tom_start:rec_start].strip()
else:
    tomato_guide_code = ""

# Extract farm-record-keeping
dry_start = current.find("replace('farming-dry-conditions'")
if rec_start != -1 and dry_start != -1:
    farm_record_code = current[rec_start:dry_start].strip()
else:
    farm_record_code = ""

# Extract farming-dry-conditions
if dry_start != -1:
    farming_dry_code = current[dry_start:current.rfind("})();")].strip()
else:
    farming_dry_code = ""

print(f"Extracted understanding-soil-ph: len {len(understanding_soil_ph_code)}")
print(f"Extracted tomato-fertilizer-guide: len {len(tomato_guide_code)}")
print(f"Extracted farm-record-keeping: len {len(farm_record_code)}")
print(f"Extracted farming-dry-conditions: len {len(farming_dry_code)}")

# Now construct the complete handbooks.js file with ALL 8 expanded handbooks!

prepare_soil_code = """  replace('prepare-soil-for-vegetables', 'How to Prepare Soil for Vegetables: Complete Practical Farmer Handbook', 'A complete, step-by-step practical handbook for vegetable land preparation: soil testing, drainage evaluation, hardpan detection, weed root clearing, organic matter incorporation, permanent raised bed creation, starter fertilization, and pre-transplanting checklists.', `
<div class="notice"><strong>How to use this handbook:</strong> Good soil preparation is not simply ploughing or throwing chemical fertilizer onto the field. It is the process of creating a healthy, well-aerated, moisture-retentive, nutrient-rich root zone where plant roots can expand without resistance. Follow these steps in exact order before sowing or transplanting.</div>

<h2>Contents</h2>
<ol>
  <li><a href="#prep-philosophy">1. The Core Philosophy of Soil Preparation</a></li>
  <li><a href="#prep-site">2. Site Inspection, Slope & Test Pit Digging</a></li>
  <li><a href="#prep-testing">3. Soil Testing & Reading Laboratory Reports</a></li>
  <li><a href="#prep-clearing">4. Land Clearing, Weed Root Removal & Residue Management</a></li>
  <li><a href="#prep-moisture">5. Soil Moisture Testing Before Working Land (The Squeeze Test)</a></li>
  <li><a href="#prep-organic">6. Organic Matter & Manure Management (Cured vs. Fresh Manure Hazards)</a></li>
  <li><a href="#prep-beds">7. Forming Permanent Raised Beds, Ridges & Pathways</a></li>
  <li><a href="#prep-starter">8. Pre-Transplanting Starter Fertilization & Row Marking</a></li>
  <li><a href="#prep-mistakes">9. Common Soil Preparation Mistakes to Avoid</a></li>
  <li><a href="#prep-checklist">10. Complete Soil Preparation Field Checklist</a></li>
</ol>

<h2 id="prep-philosophy">1. The Core Philosophy of Soil Preparation</h2>
<p>Vegetable crops are intensive feeders with delicate root systems compared to deep-rooted tree crops or wild shrubs. If soil is hard, compacted, waterlogged, or acidic, root growth is restricted, fertilizer absorption drops by up to 70%, and plants become vulnerable to soil-borne fungal wilts and nematode attacks.</p>
<p>The goal of soil preparation is to optimize the <strong>4 Pillars of Soil Health</strong>:</p>
<ul>
  <li><strong>Soil Air (25% volume):</strong> Oxygen is required for root respiration and beneficial microbial activity. Compacted, waterlogged soil lacks oxygen, causing root rot.</li>
  <li><strong>Soil Water (25% volume):</strong> Available moisture held in soil micropores for plant uptake.</li>
  <li><strong>Soil Mineral Matter (45% volume):</strong> Sand, silt, and clay particles providing mechanical support and mineral nutrients.</li>
  <li><strong>Soil Organic Matter (5% volume):</strong> Biological humus, decomposed plant residue, and microorganisms that bind soil aggregates, hold water, and buffer pH.</li>
</ul>

<h2 id="prep-site">2. Site Inspection, Slope & Test Pit Digging</h2>
<p>Before bringing tractors, tillers, or hand tools into a field, conduct a thorough site audit:</p>

<h3>A. Digging Profile Test Pits</h3>
<p>Dig 3 or 4 profile test pits measuring 50 cm wide by 60 cm deep across your field:</p>
<ul>
  <li><strong>Check Topsoil Depth:</strong> Dark, fertile topsoil should ideally be 20 to 30 cm deep. Note where the lighter-colored subsoil begins.</li>
  <li><strong>Identify Hardpans / Plough Pans:</strong> Push a steel rod or screwdriver down into the pit wall. If you hit a dense, cemented layer at 15–20 cm depth created by years of shallow ploughing, this hardpan must be shattered with a subsoiler or heavy pickaxe before planting.</li>
  <li><strong>Check Water Table & Drainage:</strong> If water seeps into your test pit during dry weather, the water table is too high, and drainage ditches or high raised beds are mandatory.</li>
</ul>

<h3>B. Evaluating Slope & Contour Direction</h3>
<p>Never run beds or tilled rows straight up and down a hill. Rainstorms will wash away seed, topsoil, and fertilizer within minutes. Lay out all beds along exact horizontal contour lines (perpendicular to the slope).</p>

<h2 id="prep-testing">3. Soil Testing & Reading Laboratory Reports</h2>
<p>A soil test is the cheapest high-return investment on any farm. Collecting samples improperly leads to false fertilizer decisions.</p>

<h3>A. Correct Soil Sampling Procedure</h3>
<ol>
  <li>Divide your field into uniform sampling blocks based on soil color, slope, and past cropping history.</li>
  <li>Take 10 to 15 sub-samples in a zigzag pattern per block using a soil auger or clean spade down to a depth of 20 cm (the root zone).</li>
  <li>Avoid sampling near dung piles, compost heaps, burnt brush areas, or fence lines.</li>
  <li>Mix all sub-samples thoroughly in a clean plastic bucket. Take 500g of the mixed soil, pack it in a labelled plastic bag, and send it to an accredited soil laboratory.</li>
</ol>

<h3>B. Key Indicators on a Soil Test Report</h3>
<table>
  <thead>
    <tr>
      <th>Indicator</th>
      <th>Ideal Range for Vegetables</th>
      <th>Corrective Action if Below Ideal</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Soil pH (CaCl2)</strong></td>
      <td>5.8 – 6.5</td>
      <td>Apply Calcitic or Dolomitic Agricultural Lime 2 to 3 months before planting.</td>
    </tr>
    <tr>
      <td><strong>Organic Carbon (%)</strong></td>
      <td>2.0% – 4.0%</td>
      <td>Incorporate 10 to 20 tonnes per hectare of well-cured compost or kraal manure.</td>
    </tr>
    <tr>
      <td><strong>Available Phosphorus (P)</strong></td>
      <td>25 – 45 ppm (Resin/Bray-1)</td>
      <td>Apply Single Superphosphate (SSP) or High-P compound basal fertilizer.</td>
    </tr>
    <tr>
      <td><strong>Potassium (K)</strong></td>
      <td>0.4 – 0.8 meq/100g</td>
      <td>Apply Muriate of Potash (MOP) or Sulfate of Potash (SOP).</td>
    </tr>
  </tbody>
</table>

<h2 id="prep-clearing">4. Land Clearing, Weed Root Removal & Residue Management</h2>
<p>Clearing land properly prevents perennial weeds and soil-borne diseases from ruining your new vegetable crop:</p>
<ul>
  <li><strong>Remove Perennial Weed Roots:</strong> Couch grass (Cynodon dactylon), yellow nutsedge (Cyperus esculentus), and black black-jack must be dug up with digging forks, dried, and removed from the bed area. Chopping nutsedge with a rotary tiller spreads its underground tubers across the whole field!</li>
  <li><strong>Sanitize Diseased Crop Residues:</strong> If the previous crop suffered from bacterial wilt, early blight, or root-knot nematodes, burn or discard the infected stalks away from the field. Do not plough diseased material into new beds.</li>
  <li><strong>Retain Healthy Residues:</strong> Healthy maize or millet stover can be chopped and incorporated into the soil or saved for surface mulching.</li>
</ul>

<h2 id="prep-moisture">5. Soil Moisture Testing Before Working Land (The Squeeze Test)</h2>
<p>Working soil when it is too wet or too dry causes permanent damage to soil aggregation:</p>

<div class="notice">
  <strong>The Practical Soil Squeeze Test:</strong> Take a handful of soil from 15 cm depth and squeeze it tightly into a ball in your palm, then open your hand.
  <ul>
    <li><strong>Too Wet:</strong> If water drips out or the ball forms a shiny, sticky ribbon that smears when rubbed, <strong>STOP!</strong> Tilling now will destroy soil structure and form hard, brick-like clods when dry. Wait 3 to 5 days for the soil to dry.</li>
    <li><strong>Too Dry:</strong> If the soil crumbles into dusty powder and cannot hold a ball shape at all, working it will create fine dust that crusts severely after rain. Irrigate lightly 48 hours before tilling.</li>
    <li><strong>Ideal Working Moisture (Field Capacity):</strong> The soil forms a moist ball that holds shape when touched, but crumbles easily into loose, soft aggregates when pressed gently with a thumb.</li>
  </ul>
</div>

<h2 id="prep-organic">6. Organic Matter & Manure Management (Cured vs. Fresh Manure Hazards)</h2>
<p>Organic matter improves sand water-holding capacity and opens up heavy clay soils for aeration. However, un-cured manure is dangerous:</p>

<h3>A. The Dangers of Fresh Manure</h3>
<ul>
  <li><strong>Ammonia Root Burn:</strong> Fresh poultry or cattle manure releases toxic ammonia gas and high soluble salts that burn tender seedling roots.</li>
  <li><strong>Weed Seed Contamination:</strong> Unfermented livestock dung contains thousands of viable weed seeds that germinate immediately after irrigation.</li>
  <li><strong>Pathogen Transfer:</strong> Fresh manure carries <em>E. coli</em> and <em>Salmonella</em> bacteria, creating severe food safety risks for fresh salad vegetables (tomatoes, lettuce, cucumber).</li>
</ul>

<h3>B. Proper Manure Curing & Application Rates</h3>
<ul>
  <li>Pile raw manure with dry straw/maize stalks, keep damp, and turn every 2 weeks for 60 to 90 days until the pile cools down, smells like rich forest soil, and turns dark brown/black.</li>
  <li><strong>Application Rate:</strong> Apply 1 to 2 shovels (approx. 5 kg) of cured compost per square metre of bed area, incorporating it into the top 15 cm of soil 14 days before planting.</li>
</ul>

<h2 id="prep-beds">7. Forming Permanent Raised Beds, Ridges & Pathways</h2>
<p>Raised beds are superior to flat planting for almost all commercial vegetable enterprises:</p>

<table>
  <thead>
    <tr>
      <th>Bed Dimension</th>
      <th>Standard Commercial Measurement</th>
      <th>Practical Reason / Benefit</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Bed Top Width</strong></td>
      <td>1.0 m to 1.2 m</td>
      <td>Allows workers to reach the middle of the bed from both sides without stepping on the soil and compacting roots.</td>
    </tr>
    <tr>
      <td><strong>Pathway Width</strong></td>
      <td>45 cm to 50 cm</td>
      <td>Provides comfortable walking space for spraying, weeding, and carrying harvest crates.</td>
    </tr>
    <tr>
      <td><strong>Bed Height</strong></td>
      <td>15 cm to 25 cm (up to 30 cm in heavy rain areas)</td>
      <td>Ensures rapid water drainage, superior root aeration, and prevents seedling drowning during flash floods.</td>
    </tr>
  </tbody>
</table>

<h2 id="prep-starter">8. Pre-Transplanting Starter Fertilization & Row Marking</h2>
<p>Once beds are formed, prepare them for planting precision:</p>
<ol>
  <li><strong>Broadcast Basal Fertilizer:</strong> Apply soil-test recommended basal compound fertilizer (e.g., Compound C 6:18:12 or Compound D 7:14:7) at 30g to 50g per linear metre of bed.</li>
  <li><strong>Incorporate Lightly:</strong> Rake the fertilizer into the top 5–10 cm of soil so it does not sit on the surface where rain washes it into pathways.</li>
  <li><strong>Mark Planting Rows with String Lines:</strong> Stretch a tight string line along the bed. Use a pre-marked wooden measuring stick to dibble planting holes at exact spacing distances (e.g., 40 cm for cabbages, 50 cm for tomatoes). Never guess spacing by eye!</li>
  <li><strong>Pre-Irrigate Beds:</strong> Run drip lines or sprinklers for 1 to 2 hours the day before transplanting so seedlings are planted into moist, cool soil.</li>
</ol>

<h2 id="prep-mistakes">9. Common Soil Preparation Mistakes to Avoid</h2>
<ul>
  <li>Tilling wet clay soil and creating rock-hard clods that ruin seedling root establishment.</li>
  <li>Applying raw, un-cured chicken manure 2 days before transplanting and burning seedling roots.</li>
  <li>Making beds wider than 1.2 metres, forcing workers to step on the bed and compact the soil.</li>
  <li>Ignoring soil pH and applying expensive fertilizers that remain chemically locked in acidic soil.</li>
  <li>Rushing planting without testing irrigation lines for leaks or clogged emitters first.</li>
</ul>

<h2 id="prep-checklist">10. Complete Soil Preparation Field Checklist</h2>
<div class="notice">
  <ul>
    <li>[ ] Profile pits dug; hardpan layers checked and shattered.</li>
    <li>[ ] Representative soil sample sent to lab and results received.</li>
    <li>[ ] Agricultural lime applied 60–90 days prior if soil pH was below 5.8.</li>
    <li>[ ] Perennial weeds cleared and diseased plant residues sanitized.</li>
    <li>[ ] Soil squeeze test performed to ensure ideal moisture before tilling.</li>
    <li>[ ] Well-cured manure/compost incorporated at 5kg/m² 14 days prior.</li>
    <li>[ ] Raised beds shaped (1.0m width, 20cm height, 50cm paths) along contours.</li>
    <li>[ ] Basal fertilizer incorporated into top 10cm of bed surface.</li>
    <li>[ ] Planting rows marked accurately with string lines and measuring sticks.</li>
    <li>[ ] Beds pre-irrigated and checked for uniform moisture depth before planting.</li>
  </ul>
</div>
`);"""

beginner_mistakes_code = """  replace('beginner-farming-mistakes', 'Common Mistakes Beginner Farmers Make: Complete Practical Farmer Handbook', 'A complete practical farmer handbook detailing the 9 fatal mistakes beginner farmers make in market planning, soil testing, water sizing, seed selection, crop spacing, chemical spraying, cash flow management, and crop rotation—with practical step-by-step solutions.', `
<div class="notice"><strong>How to use this handbook:</strong> Over 70% of new agricultural enterprises fail within their first two seasons—not because farming is impossible, but because beginner farmers repeat the exact same preventable mistakes. Read this handbook to audit your farm operations, stop financial leaks, and safeguard your capital before investing.</div>

<h2>Contents</h2>
<ol>
  <li><a href="#mis-overview">1. The Reality of Farm Failure & The Prevention Framework</a></li>
  <li><a href="#mis-1">2. Mistake #1: Planting Without Market Confirmation & Price Scenarios</a></li>
  <li><a href="#mis-2">3. Mistake #2: Buying Fertilizer & Lime Without Soil Testing</a></li>
  <li><a href="#mis-3">4. Mistake #3: Undersizing Water Supply & Pumping Capacity</a></li>
  <li><a href="#mis-4">5. Mistake #4: Planting Saved Seed from Hybrid Crops</a></li>
  <li><a href="#mis-5">6. Mistake #5: Incorrect Crop Spacing & Overcrowding Plants</a></li>
  <li><a href="#mis-6">7. Mistake #6: Reactive Chemical Spraying Without Field Scouting</a></li>
  <li><a href="#mis-7">8. Mistake #7: Mixing Household Money with Farm Cash Flow</a></li>
  <li><a href="#mis-8">9. Mistake #8: Ignoring Hardpans, Soil Drainage & Organic Matter</a></li>
  <li><a href="#mis-9">10. Mistake #9: Monocropping & Ignoring Crop Family Rotation</a></li>
  <li><a href="#mis-matrix">11. Summary Matrix & Beginner Farmer Action Checklist</a></li>
</ol>

<h2 id="mis-overview">1. The Reality of Farm Failure & The Prevention Framework</h2>
<p>Agriculture is an unforgiving commercial business where biology, weather, market volatility, and operational timing intersect. A mistake made on Day 1 (such as choosing an unmarketable crop variety or planting in acid soil) cannot be corrected on Day 60, no matter how much money or labor you pour into the field later.</p>
<p>Successful commercial farmers treat farming as a high-discipline production process. By identifying and eliminating the 9 classic beginner mistakes detailed below, you instantly place your farm in the top 20% of profitable agricultural enterprises.</p>

<h2 id="mis-1">2. Mistake #1: Planting Without Market Confirmation & Price Scenarios</h2>
<p>The single biggest reason beginner farmers go bankrupt is growing a crop first and searching for buyers when crates are piling up on the roadside. Perishable vegetables like tomatoes, green peppers, and leafy greens lose 10% of their market value every single day they sit un-harvested in hot weather.</p>

<h3>The Solution: Reverse Market Planning</h3>
<ol>
  <li><strong>Identify Off-Takers Before Buying Seed:</strong> Visit wholesale markets, fresh produce vendors, supermarkets, schools, and processors. Ask: <em>"Which exact variety, size, color, and package size do you buy, and in what weekly quantities?"</em></li>
  <li><strong>Calculate Back-Scheduled Planting Dates:</strong> If market prices peak in December during holidays, back-schedule your nursery sowing and transplanting dates so harvest coincides with peak demand.</li>
  <li><strong>Run 3 Price Scenarios in Your Budget:</strong>
    <ul>
      <li><em>Optimistic Price ($1.00/kg):</em> High profit scenario.</li>
      <li><em>Expected Price ($0.60/kg):</em> Normal market budget.</li>
      <li><em>Glut / Worst-Case Price ($0.30/kg):</em> Your break-even test. If your cost of production is $0.35/kg, a market glut will ruin you unless your cost structure is tight!</li>
    </ul>
  </li>
</ol>

<h2 id="mis-2">3. Mistake #2: Buying Fertilizer & Lime Without Soil Testing</h2>
<p>Beginners often walk into agrochemical shops and ask for "the best vegetable fertilizer," buying generic NPK compounds because a neighbor used them. Applying fertilizer without a soil test leads to two major losses:</p>
<ul>
  <li><strong>Wasted Money:</strong> Applying expensive phosphorus to a field that already has high phosphorus reserves, while ignoring severe potassium or zinc deficiencies.</li>
  <li><strong>Nutrient Lockout:</strong> Applying NPK fertilizer to soil with a pH below 5.2. In strongly acidic soils, up to 70% of applied phosphorus binds tightly to aluminum and iron, becoming chemically unavailable to roots. You spend $500 on fertilizer, but plants absorb only $150 worth!</li>
</ul>

<h3>The Solution: Test Soil First</h3>
<p>Spend $30 to $50 on a professional laboratory soil test before buying a single bag of fertilizer. Apply agricultural lime 60 to 90 days before planting to adjust pH to 6.0–6.5, unlocking natural soil nutrients and maximizing fertilizer efficiency.</p>

<h2 id="mis-3">4. Mistake #3: Undersizing Water Supply & Pumping Capacity</h2>
<p>Beginners frequently calculate water needs based on rainy season conditions or assume a small 0.5 HP domestic pump or shallow well can irrigate 1 hectare of commercial tomatoes. When mid-season heatwaves hit in October, the well dries up or the pump burns out, leading to total crop collapse during flowering.</p>

<table>
  <thead>
    <tr>
      <th>Crop Enterprise</th>
      <th>Peak Daily Water Demand (Hot Weather)</th>
      <th>Minimum Water Supply Required per Hectare</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Tomatoes / Peppers (Trellised)</strong></td>
      <td>60,000 to 70,000 Litres / ha / day (6–7 mm/day)</td>
      <td>Borehole yield &ge; 8,000 to 10,000 Litres per hour</td>
    </tr>
    <tr>
      <td><strong>Cabbages / Brassicas</strong></td>
      <td>50,000 to 60,000 Litres / ha / day (5–6 mm/day)</td>
      <td>Borehole yield &ge; 7,000 Litres per hour</td>
    </tr>
    <tr>
      <td><strong>Drip Irrigated Onions</strong></td>
      <td>40,000 to 50,000 Litres / ha / day (4–5 mm/day)</td>
      <td>Borehole yield &ge; 5,500 Litres per hour</td>
    </tr>
  </tbody>
</table>

<h3>The Solution: Audit Peak Dry-Month Water Yield</h3>
<p>Measure your water source flow rate during the hottest, driest month of the year. Size your cultivated field to match your guaranteed water supply—never expand field area beyond your peak pumping capacity!</p>

<h2 id="mis-4">5. Mistake #4: Planting Saved Seed from Hybrid (F1) Crops</h2>
<p>To save money, beginners often save seed from high-yielding supermarket tomatoes or commercial hybrid crops, planting them in the next season. The result is catastrophic: plants yield small, irregular, non-uniform fruit with zero disease resistance.</p>

<div class="notice">
  <strong>Why Hybrid (F1) Seeds Cannot Be Saved:</strong> F1 Hybrid seeds are produced by crossing two specific, pure inbred parent lines to achieve "hybrid vigor" (uniformity, high yield, disease resistance). Seeds harvested from F1 crops split genetically in the F2 generation, producing a wild mix of weak, low-yielding, non-uniform plants. Always buy fresh certified F1 hybrid seed packages from authorized dealers for commercial vegetable crops!
</div>

<h2 id="mis-5">6. Mistake #5: Incorrect Crop Spacing & Overcrowding Plants</h2>
<p>Beginner logic suggests: <em>"If I squeeze 20,000 tomato plants into a field instead of 10,000, I will get double the yield!"</em> In reality, overcrowding causes severe losses:</p>
<ul>
  <li><strong>Shading & Stunted Growth:</strong> Overcrowded leaves block sunlight, leading to tall, spindly, weak stems that fall over.</li>
  <li><strong>Humid Microclimate & Disease Outbreaks:</strong> Dense plant canopies trap moisture and stop airflow, creating ideal conditions for early blight, late blight, powdery mildew, and botrytis rot.</li>
  <li><strong>Small, Low-Grade Produce:</strong> Roots compete aggressively for water and fertilizer, producing small, unmarketable fruit that commands bargain basement prices.</li>
</ul>

<h3>The Solution: Follow Proven Spacing Standards</h3>
<p>Maintain recommended row and plant spacing (e.g., 50 cm x 100 cm for tomatoes = 20,000 plants/ha; 40 cm x 60 cm for cabbages = 41,600 plants/ha). Proper spacing increases Grade 1 yield and cuts fungicide spray costs by 40%!</p>

<h2 id="mis-6">7. Mistake #6: Reactive Chemical Spraying Without Field Scouting</h2>
<p>Beginners make two opposite mistakes with farm chemicals:</p>
<ol>
  <li><strong>Calendar Spraying:</strong> Spraying heavy toxic insecticides every Monday regardless of whether pests are present, wasting money and killing beneficial predator insects (ladybirds, predatory mites).</li>
  <li><strong>Panic Spraying:</strong> Ignoring fields until leaves are devoured or plants are wilting, then rushing to spray wrong chemicals at double dosage.</li>
</ol>

<h3>The Solution: Twice-Weekly Field Scouting Walk</h3>
<p>Walk your fields twice a week in a 'W' pattern. Inspect leaf undersides, growing tips, and soil level. Identify the exact pest or fungus first, verify if it exceeds economic injury thresholds, and select the correct registered agrochemical with the proper Pre-Harvest Interval (PHI).</p>

<h2 id="mis-7">8. Mistake #7: Mixing Household Money with Farm Cash Flow</h2>
<p>Treating harvest revenue as personal spending cash is the fastest way to kill a farm business. A farmer sells $3,000 worth of cabbages, buys a personal television or pays non-farm expenses, and suddenly has zero cash left to purchase seeds, fertilizer, and diesel for the next crop cycle.</p>

<h3>The Solution: Open a Dedicated Farm Bank Account</h3>
<ul>
  <li>Deposit 100% of all harvest sales into a separate farm business account or dedicated mobile money wallet.</li>
  <li>Pay yourself a fixed monthly manager salary from the farm account.</li>
  <li>Reinvest remaining net profits back into input procurement, equipment maintenance, and working capital cash reserves.</li>
</ul>

<h2 id="mis-8">9. Mistake #8: Ignoring Hardpans, Soil Drainage & Organic Matter</h2>
<p>Rushing to plant without fixing underlying soil physical constraints leads to stunted crops:</p>
<ul>
  <li><strong>Plough Pan Hardness:</strong> Subsurface hardpans stop taproots from reaching deep moisture during dry spells.</li>
  <li><strong>Waterlogging:</strong> Poorly drained flat beds suffocate roots within 24 hours of heavy rainfall.</li>
  <li><strong>Low Organic Carbon:</strong> Sandy soils without organic matter lose applied fertilizer within two irrigations due to leaching.</li>
</ul>

<h3>The Solution: Subsoil, Build Raised Beds & Add Organic Humus</h3>
<p>Shatter subsurface hardpans, build permanent raised beds (15–20 cm high) for superior drainage, and incorporate 10 to 20 tonnes per hectare of well-cured compost or kraal manure every season.</p>

<h2 id="mis-9">10. Mistake #9: Monocropping & Ignoring Crop Family Rotation</h2>
<p>Planting tomatoes, potatoes, or peppers in the exact same bed season after season builds up massive populations of root-knot nematodes, bacterial wilt (Ralstonia), and fusarium oxysporum in the soil. By season three, the soil becomes "tomato sick," and entire fields wilt and die within days.</p>

<h3>The Solution: Enforce a 3- to 4-Year Crop Family Rotation</h3>
<p>Rotate crops by botanical family: <strong>Nightshades (Solanaceae) &rarr; Grasses/Cereals (Poaceae) &rarr; Legumes (Fabaceae) &rarr; Brassicas (Brassicaceae)</strong>. Never follow tomatoes with potatoes, eggplant, or peppers!</p>

<h2 id="mis-matrix">11. Summary Matrix & Beginner Farmer Action Checklist</h2>
<table>
  <thead>
    <tr>
      <th>Beginner Mistake</th>
      <th>Immediate Financial Danger</th>
      <th>Corrective Professional Action</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>1. No Market Plan</strong></td>
      <td>Harvest rots unsold; 100% loss of capital.</td>
      <td>Confirm buyer specs & back-schedule planting.</td>
    </tr>
    <tr>
      <td><strong>2. No Soil Test</strong></td>
      <td>Up to 70% fertilizer locked up in acidic soil.</td>
      <td>Test soil pH & apply lime 60 days before planting.</td>
    </tr>
    <tr>
      <td><strong>3. Undersized Water</strong></td>
      <td>Total crop wilting & fruit drop during heatwaves.</td>
      <td>Match field size to dry-month peak pump yield.</td>
    </tr>
    <tr>
      <td><strong>4. Saved Hybrid Seed</strong></td>
      <td>Non-uniform, low-yielding, diseased crops.</td>
      <td>Buy fresh certified F1 hybrid seed packages.</td>
    </tr>
    <tr>
      <td><strong>5. Overcrowding</strong></td>
      <td>Fungal epidemics & unmarketable small fruit.</td>
      <td>Enforce standard spacing for airflow & light.</td>
    </tr>
    <tr>
      <td><strong>6. Calendar Spraying</strong></td>
      <td>Wasted money, chemical resistance & fruit toxins.</td>
      <td>Scout fields twice weekly; spray at thresholds.</td>
    </tr>
    <tr>
      <td><strong>7. Commingling Cash</strong></td>
      <td>Zero working capital for next season's inputs.</td>
      <td>Separate farm account & pay fixed manager salary.</td>
    </tr>
    <tr>
      <td><strong>8. Poor Drainage</strong></td>
      <td>Root rot & seedling drowning during heavy rain.</td>
      <td>Build raised beds (15–20cm) & add compost.</td>
    </tr>
    <tr>
      <td><strong>9. Monocropping</strong></td>
      <td>Soil nematode explosion & bacterial wilt ruin.</td>
      <td>Rotate botanical crop families on 3-year cycles.</td>
    </tr>
  </tbody>
</table>

<div class="notice">
  <ul>
    <li>[ ] I have visited target markets and confirmed off-taker demand and packaging.</li>
    <li>[ ] I have a laboratory soil test report and applied lime/fertilizer accordingly.</li>
    <li>[ ] My water supply delivers at least 60,000 L/ha/day during peak heat months.</li>
    <li>[ ] I am planting 100% certified seeds from an authorized dealer.</li>
    <li>[ ] Planting rows and plant spacing are marked accurately with string lines.</li>
    <li>[ ] I carry out twice-weekly field scouting walks to inspect crop health.</li>
    <li>[ ] All farm income is banked into a dedicated business account.</li>
    <li>[ ] All planting beds are raised (15–20 cm) and amended with cured organic matter.</li>
    <li>[ ] My field rotation map prevents planting related crop families in succession.</li>
  </ul>
</div>
`);"""

plan_garden_code = """  replace('plan-vegetable-garden', 'How to Plan a Vegetable Garden: Complete Practical Farmer Handbook', 'A complete practical farmer handbook for designing, mapping, and establishing a high-yield vegetable garden: site selection, microclimate evaluation, permanent raised bed construction, hydro-zoning, crop family rotation, succession harvest calendars, low-cost drip setup, and companion planting.', `
<div class="notice"><strong>How to use this handbook:</strong> A high-yield vegetable garden is not built by scattering seeds at random. It requires intelligent spatial mapping, efficient water zoning, and staggered planting calendars so your household or commercial market receives a steady, non-stop harvest every week of the year.</div>

<h2>Contents</h2>
<ol>
  <li><a href="#veg-why">1. Why Garden Planning Is the Difference Between Abundance & Failure</a></li>
  <li><a href="#veg-site">2. Site Selection & Microclimate Evaluation (Sun, Water, Slope, Wind)</a></li>
  <li><a href="#veg-beds">3. Bed Architecture: Permanent Raised Beds vs. Flat Beds</a></li>
  <li><a href="#veg-hydro">4. Hydro-Zoning & Grouping Crops by Water & Light Demand</a></li>
  <li><a href="#veg-rotation">5. Crop Family Grouping & 4-Bed Rotational Mapping</a></li>
  <li><a href="#veg-succession">6. Succession Planting Calendars for Continuous Weekly Harvest</a></li>
  <li><a href="#veg-drip">7. Low-Cost Drip & Gravity Micro-Irrigation Setup</a></li>
  <li><a href="#veg-soil">8. Soil Building, Composting & Bed Nutrition</a></li>
  <li><a href="#veg-companion">9. Companion Planting & Biological Pest Barrier Borders</a></li>
  <li><a href="#veg-map">10. Master Garden Layout Map & Action Checklist</a></li>
</ol>

<h2 id="veg-why">1. Why Garden Planning Is the Difference Between Abundance & Failure</h2>
<p>Unplanned vegetable gardens suffer from predictable chaos: all 200 cabbages mature in the exact same week creating massive waste, tall maize plants cast shade over delicate lettuce beds, water is wasted on empty pathways, and soil-borne diseases wipe out nightshade crops due to lack of rotation.</p>
<p>Systematic vegetable garden planning maximizes <strong>Yield per Square Metre</strong> while minimizing labor, water, and fertilizer costs. By structuring your garden into permanent beds and executing staggered sowing schedules, a 100 m² garden plot can produce over 500 kg of fresh, high-value vegetables annually!</p>

<h2 id="veg-site">2. Site Selection & Microclimate Evaluation (Sun, Water, Slope, Wind)</h2>
<p>Before driving a single stake into the ground, evaluate the natural physical assets of your site:</p>
<ul>
  <li><strong>Sunlight Exposure (6 to 8 Hours Minimum):</strong> Vegetable crops (especially fruiting vegetables like tomatoes, peppers, eggplants, and cucumbers) require a minimum of 6 to 8 hours of direct, unfiltered sunlight daily for photosynthesis. Avoid placing main beds under deep tree shade or directly against high building walls on the southern shadow side.</li>
  <li><strong>Proximity to Water Source:</strong> The number one reason gardens are abandoned mid-season is distance from water. If workers have to carry heavy 20-litre buckets 100 metres to water beds, irrigation will be neglected during dry spells. Place your primary garden beds within 10 to 15 metres of your water tap, tank, or pump.</li>
  <li><strong>Protection from Prevailing Winds:</strong> Strong, hot dry winds desiccate tender leaves, break trellised plants, and increase water loss by 40%. Plant live windbreak hedges (such as pigeon pea, vetiver grass, or tecoma) along the windward perimeter of your garden.</li>
  <li><strong>Slope & Drainage Safety:</strong> Select gently sloping or flat land. Avoid low-lying hollows (frost pockets) where cold air settles in winter, or flood zones where storm runoff collects.</li>
</ul>

<h2 id="veg-beds">3. Bed Architecture: Permanent Raised Beds vs. Flat Beds</h2>
<p>The foundation of a productive vegetable garden is the layout of permanent growing beds separated by dedicated walking pathways:</p>

<table>
  <thead>
    <tr>
      <th>Bed Feature</th>
      <th>Permanent Raised Beds (Recommended)</th>
      <th>Flat / In-Ground Beds</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Bed Dimensions</strong></td>
      <td>Width: 1.0 m to 1.2 m; Length: 5 m to 10 m; Height: 15 cm to 25 cm</td>
      <td>Width: Variable; Length: Variable; Height: Flat with soil surface</td>
    </tr>
    <tr>
      <td><strong>Soil Compaction</strong></td>
      <td><strong>Zero Compaction:</strong> Workers step ONLY on pathways. Bed soil remains loose, friable, and aerated indefinitely.</td>
      <td><strong>High Compaction:</strong> Foot traffic and tools crush soil pores, requiring re-ploughing every season.</td>
    </tr>
    <tr>
      <td><strong>Drainage & Aeration</strong></td>
      <td><strong>Superior:</strong> Excess water drains quickly into pathways; roots never drown during flash rainstorms.</td>
      <td><strong>Poor in Clay:</strong> Surface water ponds after rain, causing root rot and soil crusting.</td>
    </tr>
    <tr>
      <td><strong>Fertilizer Efficiency</strong></td>
      <td><strong>100% Target Placement:</strong> Compost and fertilizers are applied strictly to bed tops, never wasted on paths.</td>
      <td><strong>Wasted Inputs:</strong> Fertilizers are spread across entire area including paths where weeds absorb them.</td>
    </tr>
  </tbody>
</table>

<h2 id="veg-hydro">4. Hydro-Zoning & Grouping Crops by Water & Light Demand</h2>
<p>Do not plant water-hungry leafy greens next to drought-hardy root crops in the same bed! Group vegetables into specific <strong>Hydro-Zones</strong> to eliminate water waste:</p>

<ul>
  <li><strong>Zone A (High Water Demand / Heavy Feeders):</strong> Lettuce, spinach, Swiss chard, cabbage, cucumber, celery. These crops have shallow root systems and require daily or alternate-day consistent soil moisture. Place Zone A beds closest to your water source!</li>
  <li><strong>Zone B (Moderate Water Demand / Fruiting Crops):</strong> Tomato, pepper, eggplant, green bean, squash, sweet corn. Require deep, thorough watering 2 to 3 times a week, with reduced watering during fruit ripening.</li>
  <li><strong>Zone C (Low Water Demand / Root Crops & Alliums):</strong> Carrot, beetroot, onion, garlic, sweet potato, cassava. Require moderate moisture during germination, but thrive on reduced watering as roots/bulbs swell. Excess water causes root rotting and bulb cracking!</li>
</ul>

<h2 id="veg-rotation">5. Crop Family Grouping & 4-Bed Rotational Mapping</h2>
<p>Organize your garden beds into 4 distinct operational blocks to execute a seamless 4-year crop family rotation:</p>

<table>
  <thead>
    <tr>
      <th>Bed Block</th>
      <th>Crop Family Group</th>
      <th>Example Crops Included</th>
      <th>Agronomic Function in Rotation</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Block 1</strong></td>
      <td><strong>Solanaceae (Nightshades)</strong></td>
      <td>Tomato, Pepper, Eggplant, Potato</td>
      <td>Heavy nutrient feeders; require staking, trellising, and strict blight scouting.</td>
    </tr>
    <tr>
      <td><strong>Block 2</strong></td>
      <td><strong>Fabaceae (Legumes)</strong></td>
      <td>Green Bean, Peas, Cowpea, Groundnut</td>
      <td><strong>Nitrogen Fixers:</strong> Rhizobia bacteria on roots fix atmospheric nitrogen, enriching soil for the next crop!</td>
    </tr>
    <tr>
      <td><strong>Block 3</strong></td>
      <td><strong>Brassicaceae (Brassicas)</strong></td>
      <td>Cabbage, Kale, Rape, Broccoli, Cauliflower</td>
      <td>Heavy nitrogen consumers; utilize nitrogen left behind by Block 2 legumes!</td>
    </tr>
    <tr>
      <td><strong>Block 4</strong></td>
      <td><strong>Alliums & Root Crops</strong></td>
      <td>Onion, Garlic, Carrot, Beetroot</td>
      <td>Light feeders; deep root tap action breaks subsoil pan and cleanses soil before returning to Block 1.</td>
    </tr>
  </tbody>
</table>

<div class="notice">
  <strong>Rotation Rule:</strong> Every season, shift each crop group to the next block in sequence (Block 1 &rarr; Block 2 &rarr; Block 3 &rarr; Block 4 &rarr; Block 1). This simple rule completely starves soil-borne pests and diseases!
</div>

<h2 id="veg-succession">6. Succession Planting Calendars for Continuous Weekly Harvest</h2>
<p>To avoid the "harvest glut and famine cycle," practice <strong>Staggered Succession Planting</strong>:</p>

<h3>A. Staggered Interval Sowing</h3>
<p>Instead of planting 100 lettuce or spinach seeds on one day, plant 20 seeds every 14 days. This guarantees a steady harvest of 20 fresh heads every single week for 5 consecutive months!</p>

<h3>B. Days-to-Maturity Staggering</h3>
<p>Plant different varieties of the same crop that mature at different speeds on the exact same day:</p>
<ul>
  <li><em>Early Variety Cabbage (e.g. Gloria F1):</em> Matures in 65 days.</li>
  <li><em>Medium Variety Cabbage (e.g. Marcanta F1):</em> Matures in 80 days.</li>
  <li><em>Late Variety Cabbage (e.g. Megaton F1):</em> Matures in 105 days.</li>
</ul>

<h2 id="veg-drip">7. Low-Cost Drip & Gravity Micro-Irrigation Setup</h2>
<p>Hand-watering with cans loses up to 50% of water to evaporation and causes fungal leaf spots. Install a simple <strong>Gravity Drum Drip System</strong>:</p>
<ol>
  <li><strong>Elevate a 200-Litre Drum:</strong> Place a 200L plastic drum on a secure 1.5-metre-high brick or timber stand at the high end of the garden.</li>
  <li><strong>Connect Mainline Pipe:</strong> Install a 25 mm (1-inch) HDPE mainline pipe from the drum tap running along the top of your garden beds, fitted with a 120-mesh disk filter to stop dirt clogging.</li>
  <li><strong>Lay Drip Tape Lines:</strong> Run 16 mm drip tape (with 20 cm or 30 cm emitter spacing) down the length of each bed. Connect drip lines to the mainline with simple valve off-takes.</li>
  <li><strong>Operation:</strong> Fill the drum twice daily. Gravity pressure (0.15 bar) delivers precise water drops directly to plant root zones with zero evaporation!</li>
</ol>

<h2 id="veg-soil">8. Soil Building, Composting & Bed Nutrition</h2>
<p>Maintain permanent raised beds with continuous organic soil building:</p>
<ul>
  <li><strong>3-Bin Farm Composting System:</strong> Build three 1m x 1m compost bays using wooden pallets. Bay 1 = Fresh green leaves + dry brown carbon layers; Bay 2 = Maturing compost undergoing turning; Bay 3 = Dark, rich, cured compost ready for beds.</li>
  <li><strong>Surface Mulching:</strong> Keep bed surfaces covered with a 5-cm layer of dry grass, clean straw, or chopped maize stalks. Mulch prevents weed seed germination, keeps soil cool (reducing soil heat stress by 8°C), and conserves 60% of bed moisture.</li>
</ul>

<h2 id="veg-companion">9. Companion Planting & Biological Pest Barrier Borders</h2>
<p>Interplant complementary flowers and herbs to attract beneficial insects and repel garden pests naturally:</p>

<table>
  <thead>
    <tr>
      <th>Main Crop</th>
      <th>Beneficial Companion Plant</th>
      <th>Biological Mechanism / Benefit</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Tomato / Pepper</strong></td>
      <td>African Marigold (Tagetes)</td>
      <td>Roots release alpha-terthienyl chemicals that kill root-knot nematodes; pungent leaves repel whiteflies!</td>
    </tr>
    <tr>
      <td><strong>Cabbage / Kale</strong></td>
      <td>Basil & Peppermint</td>
      <td>Strong aromatic essential oils confuse Diamondback Moths (DBM) and prevent egg laying.</td>
    </tr>
    <tr>
      <td><strong>Cucumber / Squash</strong></td>
      <td>Dill & Coriander</td>
      <td>Flowers attract parasitic wasps and hoverflies whose larvae devour aphids and thrips!</td>
    </tr>
  </tbody>
</table>

<h2 id="veg-map">10. Master Garden Layout Map & Action Checklist</h2>
<div class="notice">
  <ul>
    <li>[ ] Garden site selected receiving &ge; 6–8 hours of direct sunlight daily.</li>
    <li>[ ] Water source located within 15 metres of primary growing beds.</li>
    <li>[ ] Perimeter windbreak hedge planted on windward border.</li>
    <li>[ ] Permanent raised beds (1.0m wide, 20cm high, 50cm paths) built along contours.</li>
    <li>[ ] Crops hydro-zoned: High water (Zone A) near tap; Low water (Zone C) further away.</li>
    <li>[ ] 4-Bed rotational crop family plan established (Nightshades &rarr; Legumes &rarr; Brassicas &rarr; Roots).</li>
    <li>[ ] Succession sowing calendar created for bi-weekly staggered planting.</li>
    <li>[ ] Gravity drip irrigation lines installed and tested for emitter discharge.</li>
    <li>[ ] 3-Bin compost system active and beds mulched with 5cm organic cover.</li>
    <li>[ ] Marigolds and herbs planted on bed borders for biological pest suppression.</li>
  </ul>
</div>
`);"""

reduce_water_code = """  replace('reduce-water-waste', 'How to Reduce Water Waste on the Farm: Complete Practical Farmer Handbook', 'A complete practical farmer handbook to farm water efficiency: conducting water audits, repairing pipe leaks, upgrading irrigation systems (flood vs. sprinkler vs. drip), soil moisture conservation, hydro-zoning, irrigation timing, and soil tensiometer testing.', `
<div class="notice"><strong>How to use this handbook:</strong> Water waste is fuel and electricity waste. Every thousand litres of water lost to leaks, evaporation, or deep drainage represents hard cash spent on diesel pumps, solar wear, and leached fertilizer. Use this handbook to audit your farm water delivery system and cut water losses by 30% to 50%.</div>

<h2>Contents</h2>
<ol>
  <li><a href="#wat-cost">1. The Hidden Financial Cost of Farm Water Waste</a></li>
  <li><a href="#wat-audit">2. Conducting a Farm Water Audit: Measuring Delivery & System Losses</a></li>
  <li><a href="#wat-leaks">3. Spotting & Repairing Leaks, Valves, and Clogged Emitters</a></li>
  <li><a href="#wat-methods">4. Upgrading Irrigation Methods: Flood vs. Sprinkler vs. Drip Comparison</a></li>
  <li><a href="#wat-mulch">5. Soil Moisture Conservation: Mulching Materials & Canopy Cover</a></li>
  <li><a href="#wat-hydro">6. Hydro-Zoning & Grouping Crops by Water Coefficients (Kc)</a></li>
  <li><a href="#wat-timing">7. Smart Irrigation Timing & Soil Touch / Tensiometer Testing</a></li>
  <li><a href="#wat-storage">8. Rainwater Catchment & Reservoir Protection (Evaporation & Seepage)</a></li>
  <li><a href="#wat-metrics">9. Water Efficiency Metrics & Complete Farm Audit Checklist</a></li>
</ol>

<h2 id="wat-cost">1. The Hidden Financial Cost of Farm Water Waste</h2>
<p>Many farmers view water as "free" if it comes from a river or farm dam. However, moving water from a source to a crop bed incurs massive hidden financial costs:</p>
<ul>
  <li><strong>Pumping Fuel & Power Costs:</strong> Running a 5.5 HP diesel pump consumes roughly 1.2 litres of diesel per hour ($1.80/hr). Running an inefficient, leaking irrigation system 4 hours extra per day wastes over $200 per month in useless fuel!</li>
  <li><strong>Nutrient Leaching Losses:</strong> Over-watering forces water below the root zone (deep drainage), washing expensive soluble nitrogen and potassium out of reach of plant roots.</li>
  <li><strong>Pesticide Spray Expenses:</strong> Over-watering and wet overhead leaf canopies create humid microclimates that trigger explosive fungal diseases (blight, mildew, rot), forcing double expenditure on chemical sprays.</li>
</ul>

<h2 id="wat-audit">2. Conducting a Farm Water Audit: Measuring Delivery & System Losses</h2>
<p>You cannot stop water waste until you measure where your water is going. Execute a simple 4-step farm water audit:</p>

<ol>
  <li><strong>Measure Pump / Source Flow Rate (The Bucket & StopWatch Test):</strong> Place a 20-litre bucket under your pump outlet or main delivery pipe. Time exactly how many seconds it takes to fill:
    $$\\text{Flow Rate (L/hr)} = \\frac{20 \\text{ Litres}}{\\text{Seconds to Fill}} \\times 3,600$$
    <em>Example:</em> If a 20L bucket fills in 10 seconds: $(20 / 10) \\times 3600 = 7,200 \\text{ Litres per hour}$.
  </li>
  <li><strong>Calculate Total Water Pumped Daily:</strong> Multiply flow rate by hours run per day. (e.g., $7,200 \\text{ L/hr} \\times 5 \\text{ hours} = 36,000 \\text{ Litres per day}$).</li>
  <li><strong>Calculate Theoretical Crop Demand:</strong> Calculate true crop water requirements based on field area and growth stage (e.g., 0.25 ha of tomatoes at 5 mm/day requires 12,500 Litres per day).</li>
  <li><strong>Calculate System Efficiency Gap:</strong>
    $$\\text{Water Waste} = 36,000 \\text{ L Pumped} - 12,500 \\text{ L Required} = 23,500 \\text{ Litres Wasted Daily (65% Loss!)}$$
  </li>
</ol>

<h2 id="wat-leaks">3. Spotting & Repairing Leaks, Valves, and Clogged Emitters</h2>
<p>Physical leaks are the easiest water losses to identify and fix immediately:</p>

<table>
  <thead>
    <tr>
      <th>Leak Location</th>
      <th>Visual Sign of Waste</th>
      <th>Immediate Low-Cost Repair Action</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Pump Suction Hose</strong></td>
      <td>Air bubbles in discharge stream; pump loses prime repeatedly.</td>
      <td>Tighten hose clamps; wrap threaded foot-valve joints with Teflon tape.</td>
    </tr>
    <tr>
      <td><strong>Mainline Pipe Couplings</strong></td>
      <td>Muddy pools around PVC or HDPE fittings when pump runs.</td>
      <td>Replace worn rubber O-rings; apply PVC solvent cement to cracked joints.</td>
    </tr>
    <tr>
      <td><strong>Control Valves & Taps</strong></td>
      <td>Water dripping continuously from valve stems.</td>
      <td>Replace internal packing seals or install new ball valves.</td>
    </tr>
    <tr>
      <td><strong>Drip Tape Emitters</strong></td>
      <td>Some emitters squirt streams while others are completely dry.</td>
      <td>Flush drip lateral ends; clean 120-mesh disk filter; soak clogged lines in mild acid solution.</td>
    </tr>
  </tbody>
</table>

<h2 id="wat-methods">4. Upgrading Irrigation Methods: Flood vs. Sprinkler vs. Drip Comparison</h2>
<p>The irrigation method you choose dictates your baseline water efficiency:</p>

<table>
  <thead>
    <tr>
      <th>Irrigation System</th>
      <th>Application Efficiency (%)</th>
      <th>Water Wasted to Evaporation / Runoff</th>
      <th>Capital Cost & suitability</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Furrow / Unlined Flood</strong></td>
      <td><strong>35% – 50%</strong></td>
      <td><strong>50% – 65% Loss:</strong> Massive evaporation, unlined ditch seepage, and deep drainage at top of field.</td>
      <td>Low initial cost; extremely high long-term water and fuel waste!</td>
    </tr>
    <tr>
      <td><strong>Overhead Sprinklers</strong></td>
      <td><strong>60% – 70%</strong></td>
      <td><strong>30% – 40% Loss:</strong> High evaporation in mid-day heat; wind drift blows water off target beds.</td>
      <td>Moderate cost; wets foliage (high disease risk); suitable for pastures/grains.</td>
    </tr>
    <tr>
      <td><strong>Drip Irrigation (Surface/Subsurface)</strong></td>
      <td><strong>90% – 95%</strong></td>
      <td><strong>5% – 10% Loss:</strong> Minimal evaporation; water applied drop-by-drop directly into root zone soil!</td>
      <td>Higher initial setup cost; lowest operating cost and maximum yield per drop.</td>
    </tr>
  </tbody>
</table>

<h2 id="wat-mulch">5. Soil Moisture Conservation: Mulching Materials & Canopy Cover</h2>
<p>Once water enters the soil, protect it from surface evaporation caused by sun heat and wind:</p>
<ul>
  <li><strong>Organic Mulching:</strong> Apply a 5 to 10 cm layer of dry grass, wheat straw, chopped maize stover, or wood shavings over planting beds. Mulched soil loses 60% less water to evaporation than bare soil!</li>
  <li><strong>Soil Temperature Suppression:</strong> Mulch keeps soil temperatures 6°C to 10°C cooler during hot afternoons, preventing root heat stress and preserving root hair vitality.</li>
  <li><strong>Black / Two-Tone Plastic Mulch:</strong> In high-value commercial vegetable production, lay 30-micron UV-stabilized plastic mulch over drip-irrigated beds. Plastic mulch eliminates 95% of evaporation and completely suppresses weed growth.</li>
</ul>

<h2 id="wat-hydro">6. Hydro-Zoning & Grouping Crops by Water Coefficients (Kc)</h2>
<p>Crop water consumption changes dramatically across growth stages and species. Use the **Crop Coefficient ($K_c$)** to match irrigation delivery to real crop demand:</p>

$$\\text{Crop Water Demand (ETc)} = \\text{Reference Evapotranspiration (ETo)} \\times \\text{Crop Coefficient (Kc)}$$

<table>
  <thead>
    <tr>
      <th>Crop Growth Stage</th>
      <th>Typical Kc Value</th>
      <th>Irrigation Management Strategy</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Initial Stage (Seedling / Establishment)</strong></td>
      <td>0.40 – 0.50</td>
      <td>Light, frequent watering to keep top 5cm moist; avoid heavy deep watering.</td>
    </tr>
    <tr>
      <td><strong>Vegetative Stage (Rapid Leaf Growth)</strong></td>
      <td>0.70 – 0.85</td>
      <td>Increase water depth as root depth expands; maintain steady soil moisture.</td>
    </tr>
    <tr>
      <td><strong>Mid-Season Stage (Flowering & Fruit Set)</strong></td>
      <td><strong>1.05 – 1.20 (PEAK)</strong></td>
      <td><strong>CRITICAL STAGE:</strong> Never allow water stress! Water deficits now cause blossom drop and fruit rot.</td>
    </tr>
    <tr>
      <td><strong>Late Stage (Ripening & Harvest)</strong></td>
      <td>0.60 – 0.80</td>
      <td>Reduce irrigation frequency gradually to encourage fruit sugar concentration and prevent bulb splitting.</td>
    </tr>
  </tbody>
</table>

<h2 id="wat-timing">7. Smart Irrigation Timing & Soil Touch / Tensiometer Testing</h2>
<p>Watering at the wrong time of day or on a rigid clock schedule wastes thousands of litres:</p>

<h3>A. Optimal Time of Day to Irrigate</h3>
<ul>
  <li><strong>Best Window (5:00 AM to 8:00 AM):</strong> Early morning irrigation allows water to soak deep into the root zone before heat builds up, with minimal evaporation loss.</li>
  <li><strong>Avoid Mid-Day (11:00 AM to 3:00 PM):</strong> Up to 40% of sprinkler/manual water evaporates in mid-air or off hot soil before reaching roots!</li>
  <li><strong>Use Caution with Evening Overhead Watering:</strong> Watering foliage after sunset leaves leaves wet overnight, triggering powdery mildew and blight epidemics. (Drip irrigation can be run safely at night).</li>
</ul>

<h3>B. Testing Soil Moisture Before Turning on the Pump</h3>
<div class="notice">
  <strong>The Ball & Ribbon Soil Touch Test:</strong> Dig down 15 cm into your crop root zone with a trowel:
  <ul>
    <li>Squeeze soil in your palm. If it crumbles completely and leaves no moisture stain on your skin, the root zone is dry—<strong>IRRIGATE NOW</strong>.</li>
    <li>If it forms a firm, moist ball that leaves a damp outline on your hand, moisture is adequate—<strong>DO NOT IRRIGATE TODAY</strong>.</li>
    <li>If water oozes out when squeezed, the soil is saturated—<strong>STOP PUMPING</strong> to prevent root rot.</li>
  </ul>
</div>

<h2 id="wat-storage">8. Rainwater Catchment & Reservoir Protection (Evaporation & Seepage)</h2>
<p>Storing water in open farm dams or earthen ponds without protection leads to massive un-noticed losses:</p>
<ul>
  <li><strong>Stopping Seepage Losses:</strong> Unlined earthen ponds in sandy soil lose up to 50 mm of water depth daily through bottom seepage. Line storage ponds with 0.5mm UV-resistant HDPE geomembrane plastic or compact a 20cm layer of heavy bentonite clay over the pond floor.</li>
  <li><strong>Reducing Evaporation Losses:</strong> Hot winds and sun evaporate up to 2.5 metres of water depth annually from open dam surfaces. Reduce evaporation by constructing deeper, narrower ponds (3m depth) rather than shallow wide ponds, or plant shade tree borders along the windward dam perimeter.</li>
</ul>

<h2 id="wat-metrics">9. Water Efficiency Metrics & Complete Farm Audit Checklist</h2>
<div class="notice">
  <ul>
    <li>[ ] Pump flow rate measured using bucket and stopwatch test.</li>
    <li>[ ] Theoretical crop water demand calculated against actual volume pumped.</li>
    <li>[ ] Suction hose clamps, foot valves, and mainline couplings inspected for leaks.</li>
    <li>[ ] Mainline disk filter cleaned and drip lines flushed to clear clogged emitters.</li>
    <li>[ ] Overhead sprinkler or flood systems audited for upgrade to efficient drip tape.</li>
    <li>[ ] All planting beds covered with 5–10cm layer of organic mulch or plastic mulch.</li>
    <li>[ ] Crops grouped into hydro-zones based on growth stage and water demand (Kc).</li>
    <li>[ ] Primary irrigation scheduled during cool early morning hours (5:00–8:00 AM).</li>
    <li>[ ] Soil root zone inspected at 15cm depth before turning on irrigation pumps.</li>
    <li>[ ] Farm water storage ponds lined and protected against seepage and evaporation.</li>
  </ul>
</div>
`);"""

# Assemble full JS file
full_js = f"""(function () {{
  const articles = window.AGRIBASE_CONTENT && window.AGRIBASE_CONTENT.articles;
  if (!articles) return;

  const replace = (slug, title, description, body) => {{
    const article = articles.find(item => item.slug === slug);
    if (!article) return;
    article.title = title;
    article.description = description;
    article.body = body;
  }};

  // 1. PREPARE SOIL FOR VEGETABLES
{prepare_soil_code}

  // 2. UNDERSTANDING SOIL PH
  {understanding_soil_ph_code}

  // 3. TOMATO FERTILIZER GUIDE
  {tomato_guide_code}

  // 4. FARM RECORD KEEPING FOR BEGINNERS
  {farm_record_code}

  // 5. FARMING IN DRY CONDITIONS
  {farming_dry_code}

  // 6. COMMON MISTAKES BEGINNER FARMERS MAKE
{beginner_mistakes_code}

  // 7. HOW TO PLAN A VEGETABLE GARDEN
{plan_garden_code}

  // 8. HOW TO REDUCE WATER WASTE ON THE FARM
{reduce_water_code}

}})();
"""

with open(handbooks_path, "w", encoding="utf-8") as f:
    f.write(full_js)

print(f"Successfully wrote full handbooks.js! Total bytes: {len(full_js)}")
