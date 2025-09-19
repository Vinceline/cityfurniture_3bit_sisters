let accidentData = [];
let crimeData = [];

// Updated to match iOS app boundary - 3km radius from Delray Beach center
const delrayBeachCenter = { lat: 26.4615, lon: -80.0728 };
const maxRadiusKm = 3.0; // 3km radius to match iOS boundary circle

// Utility functions
function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 3959; // Earth radius in miles
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
}

// Updated coordinate generation to match iOS boundary exactly
function generateCoordinatesWithinRadius() {
    // Generate random point within 3km radius circle
    const angle = Math.random() * 2 * Math.PI;
    const radius = Math.sqrt(Math.random()) * maxRadiusKm; // Square root for uniform distribution
    
    // Convert radius from km to degrees (approximate)
    const kmToDegrees = 1 / 111.32; // 1 degree ≈ 111.32 km
    const deltaLat = (radius * Math.cos(angle)) * kmToDegrees;
    const deltaLon = (radius * Math.sin(angle)) * kmToDegrees / Math.cos(delrayBeachCenter.lat * Math.PI / 180);
    
    return {
        lat: parseFloat((delrayBeachCenter.lat + deltaLat).toFixed(6)),
        lon: parseFloat((delrayBeachCenter.lon + deltaLon).toFixed(6))
    };
}

function isWithinDelrayBoundary(lat, lon) {
    const distance = calculateDistance(lat, lon, delrayBeachCenter.lat, delrayBeachCenter.lon);
    return distance <= maxRadiusKm * 0.621371; // Convert km to miles
}

function generateRecentDate() {
    const now = new Date();
    const daysBack = Math.floor(Math.random() * 365);
    const date = new Date(now);
    date.setDate(date.getDate() - daysBack);
    return date;
}

// Traffic Accident Data Generation
async function generateAccidentData() {
    const count = parseInt(document.getElementById('accidentCount').value);
    const realPercent = parseInt(document.getElementById('accidentRealPercent').value);
    const safetyType = document.getElementById('accidentSafety').value;

    document.getElementById('accidentStatus').innerHTML = `
        <div class="status warning">
            <div class="loading"></div>
            Generating ${count} traffic accidents within 3km radius...
        </div>
    `;

    await delay(100); // Allow UI update

    try {
        const realCount = Math.floor(count * realPercent / 100);
        const syntheticCount = count - realCount;

        accidentData = [];

        // Generate real-like data (simulated)
        for (let i = 0; i < realCount; i++) {
            const coords = generateCoordinatesWithinRadius();
            accidentData.push({
                id: `REAL_ACC_${Date.now()}_${i}`,
                lat: coords.lat,
                lon: coords.lon,
                date: generateRecentDate().toISOString().split('T')[0],
                time: `${Math.floor(Math.random() * 24).toString().padStart(2, '0')}:${Math.floor(Math.random() * 60).toString().padStart(2, '0')}`,
                severity: parseFloat((0.3 + Math.random() * 0.7).toFixed(2)),
                pedestrianInvolved: Math.random() < 0.15,
                bicycleInvolved: Math.random() < 0.08,
                dayOfWeek: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][Math.floor(Math.random() * 7)],
                weather: ['Clear', 'Cloudy', 'Rain', 'Fog'][Math.floor(Math.random() * 4)],
                roadType: ['City Street', 'State Highway', 'Residential', 'Arterial'][Math.floor(Math.random() * 4)],
                speedLimit: [25, 30, 35, 40, 45, 50][Math.floor(Math.random() * 6)],
                intersection: Math.random() < 0.35,
                lightCondition: ['Daylight', 'Dark', 'Dawn', 'Dusk'][Math.floor(Math.random() * 4)],
                address: generateRandomAddress(),
                source: 'FDOT_REAL'
            });
        }

        // Generate synthetic data with safety distribution
        const syntheticAccidents = generateSyntheticAccidents(syntheticCount, safetyType);
        accidentData.push(...syntheticAccidents);

        // Shuffle array
        accidentData = accidentData.sort(() => Math.random() - 0.5);

        // Show success
        document.getElementById('accidentStatus').innerHTML = `
            <div class="status success">
                ✅ Generated ${accidentData.length} traffic accidents within Delray Beach boundary!
            </div>
        `;

        // Show stats
        showAccidentStats();
        showAccidentPreview();
        document.getElementById('downloadAccidentBtn').disabled = false;
        document.getElementById('downloadCombinedBtn').disabled = !(accidentData.length > 0 && crimeData.length > 0);

    } catch (error) {
        document.getElementById('accidentStatus').innerHTML = `
            <div class="status error">
                ❌ Error generating accident data: ${error.message}
            </div>
        `;
    }
}

function generateSyntheticAccidents(count, safetyType) {
    const accidents = [];
    const distributions = {
        balanced: {
            veryDangerous: 0.20, dangerous: 0.25, moderate: 0.30, safe: 0.15, verySafe: 0.10
        },
        'safe-heavy': {
            veryDangerous: 0.10, dangerous: 0.15, moderate: 0.25, safe: 0.30, verySafe: 0.20
        },
        'danger-heavy': {
            veryDangerous: 0.30, dangerous: 0.30, moderate: 0.25, safe: 0.10, verySafe: 0.05
        }
    };

    const dist = distributions[safetyType];
    
    // Updated location clusters within 3km radius
    const locations = {
        veryDangerous: [
            { lat: 26.4585, lon: -80.0772, name: "Atlantic Ave & Federal Hwy" },
            { lat: 26.4600, lon: -80.0650, name: "Atlantic Ave & A1A" },
            { lat: 26.4520, lon: -80.0750, name: "Linton Blvd corridor" }
        ],
        dangerous: [
            { lat: 26.4650, lon: -80.0728, name: "Congress Ave corridor" },
            { lat: 26.4480, lon: -80.0800, name: "Military Trail" },
            { lat: 26.4550, lon: -80.0680, name: "Commercial districts" }
        ],
        moderate: [
            { lat: 26.4615, lon: -80.0900, name: "Residential west" },
            { lat: 26.4550, lon: -80.0600, name: "Residential east" },
            { lat: 26.4680, lon: -80.0750, name: "Mixed use areas" }
        ],
        safe: [
            { lat: 26.4580, lon: -80.0580, name: "Beach residential" },
            { lat: 26.4730, lon: -80.0780, name: "Quiet neighborhoods" },
            { lat: 26.4420, lon: -80.0680, name: "Suburban areas" }
        ],
        verySafe: [
            { lat: 26.4750, lon: -80.0820, name: "Gated communities" },
            { lat: 26.4450, lon: -80.0550, name: "Low traffic residential" },
            { lat: 26.4380, lon: -80.0650, name: "Quiet suburbs" }
        ]
    };

    Object.keys(dist).forEach(level => {
        const levelCount = Math.floor(count * dist[level]);
        const levelLocations = locations[level];
        const severityRange = {
            veryDangerous: [0.8, 1.0],
            dangerous: [0.6, 0.8],
            moderate: [0.4, 0.6],
            safe: [0.2, 0.4],
            verySafe: [0.0, 0.2]
        };

        for (let i = 0; i < levelCount; i++) {
            const location = levelLocations[Math.floor(Math.random() * levelLocations.length)];
            const [minSev, maxSev] = severityRange[level];
            
            // Generate coordinates near the selected location but within boundary
            let coords;
            let attempts = 0;
            do {
                const variance = 0.008; // Smaller variance to stay within boundary
                coords = {
                    lat: parseFloat((location.lat + (Math.random() - 0.5) * variance).toFixed(6)),
                    lon: parseFloat((location.lon + (Math.random() - 0.5) * variance).toFixed(6))
                };
                attempts++;
            } while (!isWithinDelrayBoundary(coords.lat, coords.lon) && attempts < 10);
            
            // Fallback to random point within boundary if location-based fails
            if (!isWithinDelrayBoundary(coords.lat, coords.lon)) {
                coords = generateCoordinatesWithinRadius();
            }
            
            accidents.push({
                id: `SYNTH_ACC_${Date.now()}_${level}_${i}`,
                lat: coords.lat,
                lon: coords.lon,
                date: generateRecentDate().toISOString().split('T')[0],
                time: `${Math.floor(Math.random() * 24).toString().padStart(2, '0')}:${Math.floor(Math.random() * 60).toString().padStart(2, '0')}`,
                severity: parseFloat((minSev + Math.random() * (maxSev - minSev)).toFixed(2)),
                pedestrianInvolved: Math.random() < (level === 'veryDangerous' ? 0.35 : level === 'dangerous' ? 0.20 : 0.10),
                bicycleInvolved: Math.random() < (level === 'veryDangerous' ? 0.25 : level === 'dangerous' ? 0.15 : 0.05),
                dayOfWeek: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][Math.floor(Math.random() * 7)],
                weather: ['Clear', 'Cloudy', 'Rain', 'Fog'][Math.floor(Math.random() * 4)],
                roadType: level === 'veryDangerous' ? 'State Highway' : level === 'dangerous' ? 'Arterial' : 'City Street',
                speedLimit: level === 'veryDangerous' ? [45, 50, 55][Math.floor(Math.random() * 3)] : 
                           level === 'dangerous' ? [35, 40][Math.floor(Math.random() * 2)] : 
                           [25, 30][Math.floor(Math.random() * 2)],
                intersection: Math.random() < (level === 'veryDangerous' ? 0.60 : 0.30),
                lightCondition: ['Daylight', 'Dark', 'Dawn', 'Dusk'][Math.floor(Math.random() * 4)],
                address: generateRandomAddress(),
                source: 'SYNTHETIC',
                safetyLevel: level
            });
        }
    });

    return accidents;
}

// Crime Data Generation
async function generateCrimeData() {
    const count = parseInt(document.getElementById('crimeCount').value);
    const realPercent = parseInt(document.getElementById('crimeRealPercent').value);
    const safetyType = document.getElementById('crimeSafety').value;

    document.getElementById('crimeStatus').innerHTML = `
        <div class="status warning">
            <div class="loading"></div>
            Generating ${count} crime incidents within 3km radius...
        </div>
    `;

    await delay(100);

    try {
        const realCount = Math.floor(count * realPercent / 100);
        const syntheticCount = count - realCount;

        crimeData = [];

        // Generate real-like crime data (simulated)
        for (let i = 0; i < realCount; i++) {
            const crimeTypes = ['theft', 'burglary', 'assault', 'vandalism', 'robbery', 'other'];
            const crimeType = crimeTypes[Math.floor(Math.random() * crimeTypes.length)];
            const coords = generateCoordinatesWithinRadius();
            
            crimeData.push({
                id: `FBI_CRIME_${Date.now()}_${i}`,
                lat: coords.lat,
                lon: coords.lon,
                date: generateRecentDate().toISOString().split('T')[0],
                time: `${Math.floor(Math.random() * 24).toString().padStart(2, '0')}:${Math.floor(Math.random() * 60).toString().padStart(2, '0')}`,
                crimeType: crimeType,
                severity: parseFloat((0.2 + Math.random() * 0.8).toFixed(2)),
                dayOfWeek: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][Math.floor(Math.random() * 7)],
                timeCategory: ['morning', 'afternoon', 'evening', 'night'][Math.floor(Math.random() * 4)],
                address: generateRandomAddress(),
                source: 'FBI_REAL'
            });
        }

        // Generate synthetic crime data
        const syntheticCrimes = generateSyntheticCrimes(syntheticCount, safetyType);
        crimeData.push(...syntheticCrimes);

        // Shuffle array
        crimeData = crimeData.sort(() => Math.random() - 0.5);

        document.getElementById('crimeStatus').innerHTML = `
            <div class="status success">
                ✅ Generated ${crimeData.length} crime incidents within Delray Beach boundary!
            </div>
        `;

        showCrimeStats();
        showCrimePreview();
        document.getElementById('downloadCrimeBtn').disabled = false;
        document.getElementById('downloadCombinedBtn').disabled = !(accidentData.length > 0 && crimeData.length > 0);

    } catch (error) {
        document.getElementById('crimeStatus').innerHTML = `
            <div class="status error">
                ❌ Error generating crime data: ${error.message}
            </div>
        `;
    }
}

function generateSyntheticCrimes(count, safetyType) {
    const crimes = [];
    const distributions = {
        balanced: {
            highCrime: 0.25, moderateHighCrime: 0.25, moderateCrime: 0.25, lowModerateCrime: 0.15, lowCrime: 0.10
        },
        'low-crime': {
            highCrime: 0.10, moderateHighCrime: 0.15, moderateCrime: 0.25, lowModerateCrime: 0.30, lowCrime: 0.20
        },
        'high-crime': {
            highCrime: 0.35, moderateHighCrime: 0.30, moderateCrime: 0.20, lowModerateCrime: 0.10, lowCrime: 0.05
        }
    };

    const dist = distributions[safetyType];
    
    // Updated crime location clusters within 3km radius
    const locations = {
        highCrime: [
            { lat: 26.4585, lon: -80.0772, name: "Atlantic Ave nightlife" },
            { lat: 26.4520, lon: -80.0750, name: "Linton Blvd commercial" },
            { lat: 26.4480, lon: -80.0800, name: "High traffic areas" }
        ],
        moderateHighCrime: [
            { lat: 26.4650, lon: -80.0728, name: "Congress Ave corridor" },
            { lat: 26.4480, lon: -80.0800, name: "Military Trail strips" },
            { lat: 26.4550, lon: -80.0680, name: "Commercial zones" }
        ],
        moderateCrime: [
            { lat: 26.4615, lon: -80.0900, name: "West residential" },
            { lat: 26.4550, lon: -80.0600, name: "East residential" },
            { lat: 26.4680, lon: -80.0750, name: "Mixed areas" }
        ],
        lowModerateCrime: [
            { lat: 26.4580, lon: -80.0580, name: "Beach residential" },
            { lat: 26.4730, lon: -80.0780, name: "Quiet neighborhoods" },
            { lat: 26.4420, lon: -80.0680, name: "Suburban zones" }
        ],
        lowCrime: [
            { lat: 26.4750, lon: -80.0820, name: "Gated communities" },
            { lat: 26.4420, lon: -80.0550, name: "Upscale residential" },
            { lat: 26.4380, lon: -80.0650, name: "Safe suburbs" }
        ]
    };

    const crimeTypesByLevel = {
        highCrime: ['violent', 'robbery', 'assault', 'theft'],
        moderateHighCrime: ['theft', 'burglary', 'vandalism', 'assault'],
        moderateCrime: ['theft', 'vandalism', 'burglary', 'other'],
        lowModerateCrime: ['theft', 'vandalism', 'other'],
        lowCrime: ['theft', 'vandalism', 'other']
    };

    Object.keys(dist).forEach(level => {
        const levelCount = Math.floor(count * dist[level]);
        const levelLocations = locations[level];
        const levelCrimeTypes = crimeTypesByLevel[level];
        const severityRange = {
            highCrime: [0.7, 1.0],
            moderateHighCrime: [0.5, 0.7],
            moderateCrime: [0.3, 0.5],
            lowModerateCrime: [0.2, 0.4],
            lowCrime: [0.0, 0.3]
        };

        for (let i = 0; i < levelCount; i++) {
            const location = levelLocations[Math.floor(Math.random() * levelLocations.length)];
            const crimeType = levelCrimeTypes[Math.floor(Math.random() * levelCrimeTypes.length)];
            const [minSev, maxSev] = severityRange[level];
            
            // Generate coordinates near the selected location but within boundary
            let coords;
            let attempts = 0;
            do {
                const variance = 0.008; // Smaller variance to stay within boundary
                coords = {
                    lat: parseFloat((location.lat + (Math.random() - 0.5) * variance).toFixed(6)),
                    lon: parseFloat((location.lon + (Math.random() - 0.5) * variance).toFixed(6))
                };
                attempts++;
            } while (!isWithinDelrayBoundary(coords.lat, coords.lon) && attempts < 10);
            
            // Fallback to random point within boundary if location-based fails
            if (!isWithinDelrayBoundary(coords.lat, coords.lon)) {
                coords = generateCoordinatesWithinRadius();
            }
            
            const timeCategories = level === 'highCrime' ? 
                ['evening', 'night', 'night', 'day'] : 
                ['day', 'evening', 'afternoon', 'morning'];
            
            crimes.push({
                id: `SYNTH_CRIME_${Date.now()}_${level}_${i}`,
                lat: coords.lat,
                lon: coords.lon,
                date: generateRecentDate().toISOString().split('T')[0],
                time: `${Math.floor(Math.random() * 24).toString().padStart(2, '0')}:${Math.floor(Math.random() * 60).toString().padStart(2, '0')}`,
                crimeType: crimeType,
                severity: parseFloat((minSev + Math.random() * (maxSev - minSev)).toFixed(2)),
                dayOfWeek: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][Math.floor(Math.random() * 7)],
                timeCategory: timeCategories[Math.floor(Math.random() * timeCategories.length)],
                address: generateRandomAddress(),
                source: 'SYNTHETIC',
                safetyLevel: level
            });
        }
    });

    return crimes;
}

function generateRandomAddress() {
    const streets = ['Atlantic Ave', 'Federal Hwy', 'Congress Ave', 'Military Trl', 'Jog Rd', 
                   'Linton Blvd', 'Germantown Rd', 'Yamato Rd', 'Spanish River Blvd'];
    const numbers = Math.floor(Math.random() * 9999) + 1;
    return `${numbers} ${streets[Math.floor(Math.random() * streets.length)]}`;
}

// Stats and Preview Functions
function showAccidentStats() {
    const realCount = accidentData.filter(a => a.source.includes('REAL')).length;
    const syntheticCount = accidentData.filter(a => a.source === 'SYNTHETIC').length;
    const pedestrianCount = accidentData.filter(a => a.pedestrianInvolved).length;
    const bicycleCount = accidentData.filter(a => a.bicycleInvolved).length;
    const fatalCount = accidentData.filter(a => a.severity >= 0.9).length;
    const realPercentage = Math.round((realCount / accidentData.length) * 100);

    document.getElementById('accidentStats').innerHTML = `
        <div class="stats">
            <div class="stat-card">
                <div class="stat-value">${accidentData.length}</div>
                <div class="stat-label">Total Accidents</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${realPercentage}%</div>
                <div class="stat-label">Real Data</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${pedestrianCount}</div>
                <div class="stat-label">Pedestrian</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${bicycleCount}</div>
                <div class="stat-label">Bicycle</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${fatalCount}</div>
                <div class="stat-label">Fatal/Severe</div>
            </div>
        </div>
    `;
}

function showCrimeStats() {
    const realCount = crimeData.filter(c => c.source === 'FBI_REAL').length;
    const syntheticCount = crimeData.filter(c => c.source === 'SYNTHETIC').length;
    const violentCount = crimeData.filter(c => ['violent', 'assault', 'robbery'].includes(c.crimeType)).length;
    const propertyCount = crimeData.filter(c => ['theft', 'burglary'].includes(c.crimeType)).length;
    const nightCount = crimeData.filter(c => c.timeCategory === 'night').length;
    const realPercentage = Math.round((realCount / crimeData.length) * 100);

    document.getElementById('crimeStats').innerHTML = `
        <div class="stats">
            <div class="stat-card">
                <div class="stat-value">${crimeData.length}</div>
                <div class="stat-label">Total Crimes</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${realPercentage}%</div>
                <div class="stat-label">Real Data</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${violentCount}</div>
                <div class="stat-label">Violent</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${propertyCount}</div>
                <div class="stat-label">Property</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${nightCount}</div>
                <div class="stat-label">Night Time</div>
            </div>
        </div>
    `;
}

function showAccidentPreview() {
    const preview = accidentData.slice(0, 5);
    document.getElementById('accidentPreview').innerHTML = `
        <div class="preview">
            <h3>Data Preview (First 5 Records)</h3>
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Date</th>
                        <th>Location</th>
                        <th>Severity</th>
                        <th>Type</th>
                        <th>Source</th>
                    </tr>
                </thead>
                <tbody>
                    ${preview.map(acc => `
                        <tr>
                            <td>${acc.id.slice(0, 15)}...</td>
                            <td>${acc.date}</td>
                            <td>${acc.lat.toFixed(4)}, ${acc.lon.toFixed(4)}</td>
                            <td>${acc.severity}</td>
                            <td>${acc.pedestrianInvolved ? 'Pedestrian' : acc.bicycleInvolved ? 'Bicycle' : 'Vehicle'}</td>
                            <td>${acc.source}</td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
}

function showCrimePreview() {
    const preview = crimeData.slice(0, 5);
    document.getElementById('crimePreview').innerHTML = `
        <div class="preview">
            <h3>Data Preview (First 5 Records)</h3>
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Date</th>
                        <th>Location</th>
                        <th>Crime Type</th>
                        <th>Severity</th>
                        <th>Source</th>
                    </tr>
                </thead>
                <tbody>
                    ${preview.map(crime => `
                        <tr>
                            <td>${crime.id.slice(0, 15)}...</td>
                            <td>${crime.date}</td>
                            <td>${crime.lat.toFixed(4)}, ${crime.lon.toFixed(4)}</td>
                            <td>${crime.crimeType}</td>
                            <td>${crime.severity}</td>
                            <td>${crime.source}</td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
}

// CSV Export Functions
function arrayToCSV(data, filename) {
    if (data.length === 0) return;

    const headers = Object.keys(data[0]);
    const csvContent = [
        headers.join(','),
        ...data.map(row => 
            headers.map(header => {
                let value = row[header];
                if (typeof value === 'string' && (value.includes(',') || value.includes('"') || value.includes('\n'))) {
                    value = `"${value.replace(/"/g, '""')}"`;
                }
                return value;
            }).join(',')
        )
    ].join('\n');

    downloadCSV(csvContent, filename);
}

function downloadCSV(csvContent, filename) {
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', filename);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}

function downloadAccidentCSV() {
    if (accidentData.length === 0) {
        alert('No accident data to download. Generate data first.');
        return;
    }

    // Convert boolean values to strings for CSV
    const csvData = accidentData.map(acc => ({
        ...acc,
        pedestrianInvolved: acc.pedestrianInvolved ? 'TRUE' : 'FALSE',
        bicycleInvolved: acc.bicycleInvolved ? 'TRUE' : 'FALSE',
        intersection: acc.intersection ? 'TRUE' : 'FALSE'
    }));

    arrayToCSV(csvData, `delray_beach_accidents_${new Date().toISOString().split('T')[0]}.csv`);
}

function downloadCrimeCSV() {
    if (crimeData.length === 0) {
        alert('No crime data to download. Generate data first.');
        return;
    }

    arrayToCSV(crimeData, `delray_beach_crimes_${new Date().toISOString().split('T')[0]}.csv`);
}

function downloadCombinedCSV() {
    if (accidentData.length === 0 || crimeData.length === 0) {
        alert('Generate both accident and crime data first.');
        return;
    }

    // Combine datasets with a type field to match your server's expected format
    const combinedData = [
        ...accidentData.map(acc => ({
            type: 'ACCIDENT',
            id: acc.id,
            lat: acc.lat,
            lon: acc.lon,
            date: acc.date,
            time: acc.time,
            severity: acc.severity,
            description: `${acc.pedestrianInvolved ? 'Pedestrian ' : ''}${acc.bicycleInvolved ? 'Bicycle ' : ''}Accident`,
            category: acc.pedestrianInvolved ? 'pedestrian' : acc.bicycleInvolved ? 'bicycle' : 'vehicle',
            dayOfWeek: acc.dayOfWeek,
            weather: acc.weather,
            roadType: acc.roadType,
            speedLimit: acc.speedLimit,
            intersection: acc.intersection ? 'TRUE' : 'FALSE',
            lightCondition: acc.lightCondition,
            address: acc.address,
            source: acc.source
        })),
        ...crimeData.map(crime => ({
            type: 'CRIME',
            id: crime.id,
            lat: crime.lat,
            lon: crime.lon,
            date: crime.date,
            time: crime.time,
            severity: crime.severity,
            description: `${crime.crimeType} crime`,
            category: crime.crimeType,
            dayOfWeek: crime.dayOfWeek,
            weather: '',
            roadType: '',
            speedLimit: '',
            intersection: '',
            lightCondition: '',
            address: crime.address,
            source: crime.source
        }))
    ];

    // Sort by date and time
    combinedData.sort((a, b) => {
        const dateA = new Date(`${a.date} ${a.time}`);
        const dateB = new Date(`${b.date} ${b.time}`);
        return dateB - dateA; // Most recent first
    });

    arrayToCSV(combinedData, `delray_beach_safety_data_combined_${new Date().toISOString().split('T')[0]}.csv`);
}